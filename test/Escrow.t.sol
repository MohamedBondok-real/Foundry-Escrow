//SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";

/// @dev Helper Contract empty with no recieve() or fallback()
/// to reject ether tranfer using call method
/// so that we can trigger custom error
contract RejectEther {
    // empty contract intentionally - no recieve() or fallback()
}

contract EscrowTest is Test {
    Escrow public escrow;

    address public buyer = makeAddr("buyer");
    address public seller = makeAddr("seller");
    address public arbiter = makeAddr("arbiter");

    uint256 public constant AMOUNT = 1 ether ;

    function setUp() public {
        escrow = new Escrow{value : AMOUNT}(buyer, seller, arbiter);
    }

    ///////////////// CONSTRUCTOR /////////////////

    function test_Constructor() public {
        assertEq(escrow.buyer() , buyer);
        assertEq(escrow.seller() , seller);
        assertEq(escrow.arbiter() , arbiter);
        assertEq(escrow.amount() , AMOUNT);
        assertEq(address(escrow).balance , AMOUNT);
        assertFalse(escrow.buyerApproved());
        assertFalse(escrow.sellerApproved());
        assertFalse(escrow.isDisputeRaised());
    }

    ///////////////// APPROVE BY BUYER /////////////////

    function test_approveByBuyer_RevertIfNotBuyer() public {
        vm.prank(seller);
        vm.expectRevert(Escrow.Escrow__OnlyBuyer.selector);
        escrow.approveByBuyer();
    }
    
    function test_approveByBuyer_NoReleaseWhenSellerHasNotApproved() public {
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.approveByBuyer();

        assertTrue(escrow.buyerApproved());
        assertFalse(escrow.sellerApproved());
        assertEq(address(escrow).balance, AMOUNT);
        assertEq(seller.balance, sellerBalanceBefore);
    }

    ///////////////// APPROVE BY SELLER /////////////////

    function test_approveBySeller_RevertIfNotSeller() public {
        vm.prank(buyer);
        vm.expectRevert(Escrow.Escrow__OnlySeller.selector);
        escrow.approveBySeller();
}

    function test_approveBySeller_NoReleaseWhenBuyerHasNotApproved() public {
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(seller);
        escrow.approveBySeller();

        assertFalse(escrow.buyerApproved());
        assertTrue(escrow.sellerApproved());
        assertEq(address(escrow).balance, AMOUNT);
        assertEq(seller.balance, sellerBalanceBefore);
    }

    ///////////////// RELEASE IF AGREED /////////////////

    function test_Release_WhenBuyerThenSellerApprove_TransferFundsToSeller() public {
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.approveByBuyer();

        vm.prank(seller);
        escrow.approveBySeller();

        assertEq(address(escrow).balance, 0);
        assertEq(seller.balance, sellerBalanceBefore + AMOUNT);
    }

    function test_Release_WhenSellerThenBuyerApprove_TransferFundsToSeller() public {
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(seller);
        escrow.approveBySeller();

        vm.prank(buyer);
        escrow.approveByBuyer();

        assertEq(address(escrow).balance, 0);
        assertEq(seller.balance, sellerBalanceBefore + AMOUNT);
    }

    function test_Release_DoesNotHappen_WhenDisputeRaised() public {
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.approveByBuyer();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(seller);
        escrow.approveBySeller();

        assertTrue(escrow.buyerApproved());
        assertTrue(escrow.sellerApproved());
        assertTrue(escrow.isDisputeRaised());
        assertEq(address(escrow).balance, AMOUNT);
        assertEq(seller.balance, sellerBalanceBefore);
    }

    function test_Release_RevertsOnTransferFailure_WhenSellerCanNotRecieveEther() public {
        RejectEther badSeller = new RejectEther();
        Escrow badEscrow = new Escrow{value : AMOUNT}(buyer,address(badSeller), arbiter);

        vm.prank(buyer);
        badEscrow.approveByBuyer();

        vm.prank(address(badSeller));
        vm.expectRevert(Escrow.Escrow__TransferFailed.selector);
        badEscrow.approveBySeller();
    }

    ///////////////// RAISE DISPUTE /////////////////

    function test_RaiseDispute_RevertsIfNotBuyerOrSeller() public {
        vm.prank(arbiter);
        vm.expectRevert(Escrow.Escrow__OnlyBuyerOrSeller.selector);
        escrow.raiseDispute();
    }

    function test_RaiseDispute_ByBuyer() public {
        vm.prank(buyer);
        escrow.raiseDispute();
        assertTrue(escrow.isDisputeRaised());
    }

    function test_RaiseDispute_BySeller() public {
        vm.prank(seller);
        escrow.raiseDispute();
        assertTrue(escrow.isDisputeRaised());
    }

    ///////////////// RESOLVE DISPUTE /////////////////

    function test_ResolveDispute_RevertsIfNotArbiter() public {
        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(buyer);
        vm.expectRevert(Escrow.Escrow__OnlyArbiter.selector);
        escrow.resolveDispute(false);
    }

    function test_ResolveDispute_RevertsIfNoDisputeRaised() public {
        vm.prank(arbiter);
        vm.expectRevert(Escrow.Escrow__NoDisputeRaised.selector);
        escrow.resolveDispute(true);
    }

    function test_ResolveDispute_ApproveForSeller_RaisedByBuyer() public {
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbiter);
        escrow.resolveDispute(true);

        assertEq(address(escrow).balance, 0);
        assertEq(seller.balance, sellerBalanceBefore + AMOUNT);
    }

    function test_ResolveDispute_ApproveForSeller_RaisedBySeller() public {
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(seller);
        escrow.raiseDispute();

        vm.prank(arbiter);
        escrow.resolveDispute(true);

        assertEq(address(escrow).balance, 0);
        assertEq(seller.balance, sellerBalanceBefore + AMOUNT);
    }

    function test_ResolveDispute_ApproveForBuyer_RaisedByBuyer() public {
        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbiter);
        escrow.resolveDispute(false);

        assertEq(address(escrow).balance, 0);
        assertEq(buyer.balance, buyerBalanceBefore + AMOUNT);
    }

    function test_ResolveDispute_ApproveForBuyer_RaisedBySeller() public {
        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(seller);
        escrow.raiseDispute();

        vm.prank(arbiter);
        escrow.resolveDispute(false);

        assertEq(address(escrow).balance, 0);
        assertEq(buyer.balance, buyerBalanceBefore + AMOUNT);
    }

    function test_ResolveDispute_RevertsOnTransferFailure_ToSeller() public {
        RejectEther badSeller = new RejectEther();
        Escrow badEscrow = new Escrow{value : AMOUNT}(buyer,address(badSeller), arbiter);

        vm.prank(buyer);
        badEscrow.raiseDispute();

        vm.prank(arbiter);
        vm.expectRevert(Escrow.Escrow__TransferFailed.selector);
        badEscrow.resolveDispute(true);
    }

    function test_ResolveDispute_RevertsOnTransferFailure_ToBuyer() public {
        RejectEther badBuyer = new RejectEther();
        Escrow badEscrow = new Escrow{value : AMOUNT}(address(badBuyer), seller, arbiter);

        vm.prank(seller);
        badEscrow.raiseDispute();

        vm.prank(arbiter);
        vm.expectRevert(Escrow.Escrow__TransferFailed.selector);
        badEscrow.resolveDispute(false);
    }
}