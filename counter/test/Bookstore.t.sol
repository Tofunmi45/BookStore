// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/BookStore.sol";

contract BookstoreTest is Test {
    Bookstore bookstore;
    address owner;
    address user;
    uint256 premiumPrice = 1 ether;

    function setUp() public {
        owner = address(this);
        user = address(0x123);
        bookstore = new Bookstore(premiumPrice);
    }

    function testDeployment() public {
        assertEq(bookstore.owner(), owner);
        assertEq(bookstore.premiumPrice(), premiumPrice);
    }

    function testAddBook() public {
        bookstore.addBook("Free Book", "This is a free book.", false);
        (string memory title, string memory content) = bookstore.getBook(1);
        assertEq(title, "Free Book");
        assertEq(content, "This is a free book.");
    }

    function testPurchasePremium() public {
        vm.deal(user, 2 ether); // Fund the user with 2 ether
        vm.prank(user); // Next transaction is sent from user
        bookstore.purchasePremium{value: premiumPrice}();
        assertTrue(bookstore.premiumMembers(user));
    }

    function testGetBook() public {
        bookstore.addBook("Free Book", "This is a free book.", false);
        bookstore.addBook("Premium Book", "This is a premium book.", true);

        (string memory title, string memory content) = bookstore.getBook(1);
        assertEq(title, "Free Book");
        assertEq(content, "This is a free book.");

        vm.deal(user, 2 ether); // Fund the user with 2 ether
        vm.prank(user); // Next transaction is sent from user
        bookstore.purchasePremium{value: premiumPrice}();

        vm.prank(user); // Next transaction is sent from user
        (title, content) = bookstore.getBook(2);
        assertEq(title, "Premium Book");
        assertEq(content, "This is a premium book.");
    }

    function testNonPremiumCannotAccessPremiumBook() public {
        bookstore.addBook("Premium Book", "This is a premium book.", true);
        vm.prank(user); // Next transaction is sent from user
        vm.expectRevert("This book is only available to premium members");
        bookstore.getBook(1);
    }

    function testWithdraw() public {
        vm.deal(user, 2 ether); // Fund the user with 2 ether
        vm.prank(user); // Next transaction is sent from user
        bookstore.purchasePremium{value: premiumPrice}();

        uint256 initialBalance = owner.balance;
        bookstore.withdraw();
        assertEq(owner.balance, initialBalance + premiumPrice);
    }
}
