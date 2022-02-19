// SPDX-License-Identifier: MIT


//   _   _          _     _            _        _           _             _   _     
//  | | | |        | |   | |          | |      | |         (_)           | | | |    
//  | |_| |__   ___| |__ | | ___   ___| | _____| |__   __ _ _ _ __    ___| |_| |__  
//  | __| '_ \ / _ \ '_ \| |/ _ \ / __| |/ / __| '_ \ / _` | | '_ \  / _ \ __| '_ \ 
//  | |_| | | |  __/ |_) | | (_) | (__|   < (__| | | | (_| | | | | ||  __/ |_| | | |
//   \__|_| |_|\___|_.__/|_|\___/ \___|_|\_\___|_| |_|\__,_|_|_| |_(_)___|\__|_| |_|
//                                                                                  
//                                                                                  

// This is a late night musing around keeping developer peer reviews immutable, transparent, and firmly within the contract itself
// Conceptually, you're looking for two external and trusted developers to give a public nod on the quality and purpose of the code.

// Not all projects can afford in depth audits and often peer-review is leveraged by the developer (for a second set of eyes) or the 
//   team, to make sure the developer is meeting needs and not doing something shady.

// This in no way replaces a proper audit.
// Its a potential trust builder in a project given recent schemes and maliscious contracts.
// A step towards community governance, maybe?


// Finally, its a prototype and not fully tested. Its nearly 2am and I'm toying with ideas.
// Cut me some slack....



pragma solidity ^0.8.9;

contract peerReview {

    struct contractData {
        bool submitted;
        bool locked;
        bool reviewOneApproved;
        bool reviewTwoApproved;
        address submittedBy;
        address reviewerOne;
        address reviewerTwo;
    }

    mapping(address => contractData) public contractReviews;

    function submitReview(address _contractAddress, address _reviewerOne, address _reviewerTwo, bool _lock) public {
        contractData memory myContractData = contractReviews[_contractAddress];
        require(!myContractData.submitted, "Record Exists");
        require(_reviewerOne != _reviewerTwo, "2 Unique Reviewers Required");

        myContractData.submittedBy = msg.sender;
        myContractData.submitted = true;
        myContractData.locked = _lock;
        myContractData.reviewerOne = _reviewerOne;
        myContractData.reviewerTwo = _reviewerTwo;

        contractReviews[_contractAddress] = myContractData;

    }

    function lockReview(address _contractAddress) public {
        contractData memory myContractData = contractReviews[_contractAddress];
        require(!myContractData.locked, "Record Locked");
        require(myContractData.submittedBy == msg.sender, "Not Authorised");

        myContractData.locked = true;

        contractReviews[_contractAddress] = myContractData;

    }

    function updateUnlockedReview(address _contractAddress, address _reviewerOne, address _reviewerTwo, bool _lock) public {
        contractData memory myContractData = contractReviews[_contractAddress];
        require(!myContractData.locked, "Record Locked");
        require(myContractData.submittedBy == msg.sender, "Not Authorised");

        myContractData.locked = _lock;

        if (myContractData.reviewerOne != _reviewerOne) {
            myContractData.reviewerOne = _reviewerOne;
            myContractData.reviewOneApproved = false;
        }

        if (myContractData.reviewerTwo != _reviewerTwo) {
            myContractData.reviewerTwo = _reviewerTwo;
            myContractData.reviewTwoApproved = false;
        }
        
        require(myContractData.reviewerOne != myContractData.reviewerTwo, "2 Unique Reviewers Required");
        contractReviews[_contractAddress] = myContractData;

    }

    function approveReview(address _contractAddress) public {
        contractData memory myContractData = contractReviews[_contractAddress];
        require(myContractData.locked, "Record Locked");

        if (msg.sender == myContractData.reviewerOne) {
            myContractData.reviewOneApproved = true;
        } else if (msg.sender == myContractData.reviewerTwo) {
            myContractData.reviewTwoApproved = true;
        } else {
            revert("You are not a listed reviewer");
        }

        contractReviews[_contractAddress] = myContractData;

    }

    function isContractPeerReviewedAndApproved(address _contractAddress) external view returns(bool) {
        contractData memory myContractData = contractReviews[_contractAddress];
        
        if (myContractData.reviewOneApproved && myContractData.reviewTwoApproved ) {
            return true;
        } else {
            return false;
        }
        
    }

}
