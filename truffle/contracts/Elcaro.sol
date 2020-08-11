// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Owned.sol";
import "./HitchensOrderStatisticsTree.sol";

contract Elcaro is Owned {
    // events
    event onRequest(address indexed node_account, bytes32 indexed request_hash, bytes data);
    event onRegister(address indexed node_account, uint256 node_count);
    event onUnregister(address indexed node_account, uint256 node_count);

    using HitchensOrderStatisticsTreeLib for HitchensOrderStatisticsTreeLib.Tree;
    HitchensOrderStatisticsTreeLib.Tree tree;

    mapping(address => uint256) nodes;
    mapping(bytes32 => uint256[]) requests;

    constructor() {
    }

    // node management
    function register() external payable returns (bool) {
        nodes[tx.origin] += msg.value;
        tree.insert(bytes32("0x00"), uint256(tx.origin));
        emit onRegister(tx.origin, tree.count());
        return true;
    }

    function unregister() external returns (bool) {
        nodes[tx.origin] = 0;
        tree.remove(bytes32("0x00"), uint256(tx.origin));
        emit onUnregister(tx.origin, tree.count());
        return true;
    }

    function nodeCount() view public returns (uint256) {
        return tree.count();
    }

    function isRegistered(uint256 _id) view public returns (bool) {
        return tree.keyExists(bytes32("0x00"), _id);
    }

    function call(string memory _function, bytes calldata _arguments, address _contract, string memory _callback) external payable returns (bool) {
        // ipfs://QmZrPf6xunDiwsdbPS33oxiPQoTeztmP6KkWfFPjBjdWH7/location(string)
        bytes memory data = abi.encode(_function, _arguments, _contract, _callback, block.number, tx.origin, msg.sender);
        bytes32 _hash = keccak256(data);
        uint256 _nearestNode = 0; //tree.atPermil(tree.permil(uint256(_hash)));
        requests[_hash].push(_nearestNode);
        emit onRequest(address(_nearestNode), _hash, data);
        return true;
    }

    function test() external payable returns (bool) {
        return this.call(
            "ipfs://QmZrPf6xunDiwsdbPS33oxiPQoTeztmP6KkWfFPjBjdWH7/location(string)", abi.encode(1, 2, 3, "Hello"),
            address(this), "updateLocation(uint256,uint256)"
        );
    }
}
