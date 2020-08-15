// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Owned.sol";
import "./EnumerableSet.sol";

contract Elcaro is Owned {
    // events
    event onRequest(address indexed node_account, bytes32 indexed request_hash, uint256 index, bytes data);
    event onRegister(address indexed node_account, uint256 node_count);
    event onUnregister(address indexed node_account, uint256 node_count);

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private nodes;

    mapping(bytes32 => address) requests;
    mapping(bytes32 => address[]) multi_requests;
//    mapping(bytes32 => EnumerableSet.AddressSet) multi_requests;

    constructor() {
    }

    // node management
    function register() external payable returns (bool) {
        if (nodes.add(tx.origin) == true)
        {
            emit onRegister(tx.origin, nodes.length());
            return true;
        }
        return false;
    }

    function unregister() external returns (bool) {
        if (nodes.remove(tx.origin) == true)
        {
            emit onUnregister(tx.origin, nodes.length());
            return true;
        }
        return false;
    }

    function nodeCount() view public returns (uint256) {
        return nodes.length();
    }

    function isRegistered(address _id) view public returns (bool) {
        return nodes.contains(_id);
    }

    function call(string memory _function, bytes calldata _arguments, address _contract, string memory _callback) external payable returns (bool) {
        // ipfs://QmZrPf6xunDiwsdbPS33oxiPQoTeztmP6KkWfFPjBjdWH7/location(string)
        bytes memory data = abi.encode(_function, _arguments, _contract, _callback, block.number, tx.origin, msg.sender);
        bytes32 _hash = keccak256(data);
        address _nearestNode = nodes.at(uint256(_hash) % nodes.length());
        requests[_hash] = _nearestNode;
        emit onRequest(_nearestNode, _hash, 0, data);
        return true;
    }

    function call_n(uint256 count, string memory _function, bytes calldata _arguments, address _contract, string memory _callback) external payable returns (bool) {
        // ipfs://QmZrPf6xunDiwsdbPS33oxiPQoTeztmP6KkWfFPjBjdWH7/location(string)
        bytes memory data = abi.encode(_function, _arguments, _contract, _callback, block.number, tx.origin, msg.sender);
        bytes32 _hash = keccak256(data);
        for (uint i = 0; i < count; ++i) {
            address _nearestNode = nodes.at((uint256(_hash) + i) % nodes.length());
            multi_requests[_hash].push(_nearestNode);
            emit onRequest(_nearestNode, _hash, i, data);
        }
        return true;
    }

    function test_hello_world() external payable returns (bool) {
        return this.call(
            "ipfs://Qmat7MMWMt6vthLJXeAngRYyuMGU3Fq1La4Ui8e2yiMLkr/hello_world(string)", abi.encode("Alex"),
            address(this), "updateLocation(uint256,uint256)"
        );
    }

    function test_get_uint256() external payable returns (bool) {
        return this.call(
            "ipfs://Qmat7MMWMt6vthLJXeAngRYyuMGU3Fq1La4Ui8e2yiMLkr/get(uint256)", abi.encode(1),
            address(this), "updateLocation(uint256,uint256)"
        );
    }

    function test_get_string() external payable returns (bool) {
        return this.call(
            "ipfs://Qmat7MMWMt6vthLJXeAngRYyuMGU3Fq1La4Ui8e2yiMLkr/get(string)", abi.encode("Hello"),
            address(this), "updateLocation(uint256,uint256)"
        );
    }

    function test_get_tuple_uint256_string() external payable returns (bool) {
        return this.call(
            "ipfs://Qmat7MMWMt6vthLJXeAngRYyuMGU3Fq1La4Ui8e2yiMLkr/get_tuple(uint256,string)", abi.encode(23, "Hello"),
            address(this), "updateLocation(uint256,uint256)"
        );
    }

    function test_get_tuple_string_uint256() external payable returns (bool) {
        return this.call(
            "ipfs://Qmat7MMWMt6vthLJXeAngRYyuMGU3Fq1La4Ui8e2yiMLkr/get_tuple(string,uint256)", abi.encode("Hello", 23),
            address(this), "updateLocation(uint256,uint256)"
        );
    }

    function test_n(uint256 count) external payable returns (bool) {
        return this.call_n(count,
            "ipfs://Qmat7MMWMt6vthLJXeAngRYyuMGU3Fq1La4Ui8e2yiMLkr/get(uint256)", abi.encode(count),
            address(this), "updateLocation(uint256,uint256)"
        );
    }
}
