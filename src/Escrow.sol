//SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;

    uint256 public amount;

    bool public buyerApproved;
    bool public sellerApproved;

    bool public isDisputeRaised;

    // Custom Errors
    error Escrow__OnlyBuyer();
    error Escrow__OnlySeller();
    error Escrow__OnlyArbiter();
    error Escrow__NoDisputeRaised();
    error Escrow__TransferFailed();
    error Escrow__OnlyBuyerOrSeller();

    // constructor
    constructor (address _buyer, address _seller, address _arbiter) payable {
        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;
        amount = msg.value;
    }

    // buyer approves the release of funds
    function approveByBuyer() external {
        //require(msg.sender == buyer , "Only buyer can approve");
        if(msg.sender != buyer) revert Escrow__OnlyBuyer();
        buyerApproved = true ;
        releaseIfAgreed();
    }

    // seller approves the release of funds
    function approveBySeller() external {
        //require(msg.sender == seller , "Only seller can approve");
        if(msg.sender != seller) revert Escrow__OnlySeller();
        sellerApproved = true ;
        releaseIfAgreed();
    }

    // arbiter resolves the dispute
    function resolveDispute(bool _approveForSeller) external {
        //require(msg.sender == arbiter , "Only arbiter can resolve dispute");
        if(msg.sender != arbiter) revert Escrow__OnlyArbiter();
        //require(isDisputeRaised,"No dispute is raised");
        if(!isDisputeRaised) revert Escrow__NoDisputeRaised();

        if (_approveForSeller){
            (bool success,) = seller.call{value : amount}("");
            if(!success)revert Escrow__TransferFailed();
        }else{
            (bool success,) = buyer.call{value : amount}("");
            if(!success)revert Escrow__TransferFailed();
        }
    }

    // if both parties approve, release the funds
    function releaseIfAgreed() internal {
        if (buyerApproved && sellerApproved && !isDisputeRaised){
            (bool success,) = seller.call{value : amount}("");
            if(!success)revert Escrow__TransferFailed();
        }
    }

    // if no aggreement, raise dispute
    function raiseDispute() external {
        //require(msg.sender == buyer || msg.sender == seller ,"Only buyer or seller can raise a dispute");
        if(msg.sender != buyer && msg.sender != seller) revert Escrow__OnlyBuyerOrSeller();

        isDisputeRaised = true;
    }
}