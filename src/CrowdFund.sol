// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    AggregatorV3Interface
} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

contract CrowdFund {
    using PriceConverter for uint256;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error CrowdFund__GoalMustBeGreaterThanZero();
    error CrowdFund__DeadlineMustBeInFuture();
    error CrowdFund__CampaignDoesNotExist();
    error CrowdFund__CampaignEnded();
    error CrowdFund__CampaignStillActive();
    error CrowdFund__MinimumContributionNotMet();
    error CrowdFund__NotCampaignOwner();
    error CrowdFund__GoalNotReached();
    error CrowdFund__AlreadyWithdrawn();
    error CrowdFund__TransferFailed();
    error CrowdFund__NoContributionFound();
    error CrowdFund__CampaignSucceeded();

    /*//////////////////////////////////////////////////////////////
                                TYPES
    //////////////////////////////////////////////////////////////*/

    enum CampaignStatus {
        Active,
        Successful,
        Failed,
        Withdrawn
    }

    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        bool withdrawn;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MINIMUM_USD = 5e18;

    AggregatorV3Interface private immutable s_priceFeed;

    Campaign[] private s_campaigns;

    // campaignId => contributor => amount funded
    mapping(uint256 => mapping(address => uint256)) private s_contributions;

    // campaignId => contributors array
    mapping(uint256 => address[]) private s_contributors;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CampaignCreated(uint256 indexed campaignId, address indexed owner);

    event Funded(uint256 indexed campaignId, address indexed contributor, uint256 amount);

    event Withdrawn(uint256 indexed campaignId, uint256 amount);

    event Refunded(uint256 indexed campaignId, address indexed contributor, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address priceFeedAddress) {
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /*//////////////////////////////////////////////////////////////
                        CAMPAIGN CREATION
    //////////////////////////////////////////////////////////////*/

    function createCampaign(string memory title, string memory description, uint256 goal, uint256 durationInDays)
        external
    {
        if (goal == 0) {
            revert CrowdFund__GoalMustBeGreaterThanZero();
        }

        uint256 deadline = block.timestamp + (durationInDays * 1 days);

        if (deadline <= block.timestamp) {
            revert CrowdFund__DeadlineMustBeInFuture();
        }

        Campaign memory newCampaign = Campaign({
            owner: msg.sender,
            title: title,
            description: description,
            goal: goal,
            deadline: deadline,
            amountRaised: 0,
            withdrawn: false
        });

        s_campaigns.push(newCampaign);

        uint256 campaignId = s_campaigns.length - 1;

        emit CampaignCreated(campaignId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            FUND CAMPAIGN
    //////////////////////////////////////////////////////////////*/

    function fundCampaign(uint256 campaignId) external payable {
        if (campaignId >= s_campaigns.length) {
            revert CrowdFund__CampaignDoesNotExist();
        }

        Campaign storage campaign = s_campaigns[campaignId];

        if (block.timestamp > campaign.deadline) {
            revert CrowdFund__CampaignEnded();
        }

        uint256 usdAmount = msg.value.getConversionRate(s_priceFeed);

        if (usdAmount < MINIMUM_USD) {
            revert CrowdFund__MinimumContributionNotMet();
        }

        if (s_contributions[campaignId][msg.sender] == 0) {
            s_contributors[campaignId].push(msg.sender);
        }

        s_contributions[campaignId][msg.sender] += msg.value;

        campaign.amountRaised += msg.value;

        emit Funded(campaignId, msg.sender, msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAW FUNDS
    //////////////////////////////////////////////////////////////*/

    function withdrawFunds(uint256 campaignId) external {
        if (campaignId >= s_campaigns.length) {
            revert CrowdFund__CampaignDoesNotExist();
        }

        Campaign storage campaign = s_campaigns[campaignId];

        if (msg.sender != campaign.owner) {
            revert CrowdFund__NotCampaignOwner();
        }

        if (block.timestamp < campaign.deadline) {
            revert CrowdFund__CampaignStillActive();
        }

        if (campaign.amountRaised < campaign.goal) {
            revert CrowdFund__GoalNotReached();
        }

        if (campaign.withdrawn) {
            revert CrowdFund__AlreadyWithdrawn();
        }

        campaign.withdrawn = true;

        uint256 amount = campaign.amountRaised;

        (bool success,) = payable(campaign.owner).call{value: amount}("");

        if (!success) {
            revert CrowdFund__TransferFailed();
        }

        emit Withdrawn(campaignId, amount);
    }

    /*//////////////////////////////////////////////////////////////
                                REFUNDS
    //////////////////////////////////////////////////////////////*/

    function claimRefund(uint256 campaignId) external {
        if (campaignId >= s_campaigns.length) {
            revert CrowdFund__CampaignDoesNotExist();
        }

        Campaign storage campaign = s_campaigns[campaignId];

        if (block.timestamp < campaign.deadline) {
            revert CrowdFund__CampaignStillActive();
        }

        if (campaign.amountRaised >= campaign.goal) {
            revert CrowdFund__CampaignSucceeded();
        }

        uint256 amountContributed = s_contributions[campaignId][msg.sender];

        if (amountContributed == 0) {
            revert CrowdFund__NoContributionFound();
        }

        // CEI Pattern
        s_contributions[campaignId][msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amountContributed}("");

        if (!success) {
            revert CrowdFund__TransferFailed();
        }

        emit Refunded(campaignId, msg.sender, amountContributed);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getCampaign(uint256 campaignId) external view returns (Campaign memory) {
        return s_campaigns[campaignId];
    }

    function getContribution(uint256 campaignId, address contributor) external view returns (uint256) {
        return s_contributions[campaignId][contributor];
    }

    function getContributors(uint256 campaignId) external view returns (address[] memory) {
        return s_contributors[campaignId];
    }

    function getCampaignCount() external view returns (uint256) {
        return s_campaigns.length;
    }

    function getCampaignStatus(uint256 campaignId) external view returns (CampaignStatus) {
        Campaign memory campaign = s_campaigns[campaignId];

        if (campaign.withdrawn) {
            return CampaignStatus.Withdrawn;
        }

        if (block.timestamp < campaign.deadline) {
            return CampaignStatus.Active;
        }

        if (campaign.amountRaised >= campaign.goal) {
            return CampaignStatus.Successful;
        }

        return CampaignStatus.Failed;
    }
}

