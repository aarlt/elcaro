// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Owned.sol";
import "./EnumerableSet.sol";
import "./IElcaro.sol";

contract Elcaro is Owned, IElcaro {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private nodes;

    // events
    event onRequest(address indexed node_account, bytes32 indexed request_hash, bytes data);
    event onMultiRequest(address indexed node_account, bytes32 indexed request_hash, uint256 index,  uint256 count, bytes data);
    event onRegister(address indexed node_account, uint256 node_count);
    event onUnregister(address indexed node_account, uint256 node_count);

    mapping(bytes32 => address) requests;
    mapping(bytes32 => address[]) multi_requests;

    constructor() {
    }

    // node management
    function register() external payable override returns (bool) {
        if (nodes.add(tx.origin) == true)
        {
            emit onRegister(tx.origin, nodes.length());
            return true;
        }
        return false;
    }

    function unregister() external override returns (bool) {
        if (nodes.remove(tx.origin) == true)
        {
            emit onUnregister(tx.origin, nodes.length());
            return true;
        }
        return false;
    }

    function nodeCount() view public override returns (uint256) {
        return nodes.length();
    }

    function isRegistered(address _id) view public override returns (bool) {
        return nodes.contains(_id);
    }

    function request(string memory _function, bytes calldata _arguments, address _contract, string memory _callback) external payable override returns (bool) {
        // ipfs://QmZrPf6xunDiwsdbPS33oxiPQoTeztmP6KkWfFPjBjdWH7/location(string)
        bytes memory data = abi.encode(_function, _arguments, _contract, _callback, block.number, tx.origin, msg.sender);
        bytes32 _hash = keccak256(data);
        address _nearestNode = nodes.at(uint256(_hash) % nodes.length());
        requests[_hash] = _nearestNode;
        emit onRequest(_nearestNode, _hash, data);
        return true;
    }

    function request_n(uint256 count, string memory _function, bytes calldata _arguments, address _contract, string memory _callback) external payable override returns (bool) {
        // ipfs://QmZrPf6xunDiwsdbPS33oxiPQoTeztmP6KkWfFPjBjdWH7/location(string)
        bytes memory data = abi.encode(_function, _arguments, _contract, _callback, block.number, tx.origin, msg.sender);
        bytes32 _hash = keccak256(data);
        for (uint i = 0; i < count; ++i) {
            address _nearestNode = nodes.at((uint256(_hash) + i) % nodes.length());
            multi_requests[_hash].push(_nearestNode);
            emit onMultiRequest(_nearestNode, _hash, i, count, data);
        }
        return true;
    }
}
