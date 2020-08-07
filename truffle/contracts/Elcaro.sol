// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./Owned.sol";
import "./HitchensOrderStatisticsTree.sol";

contract Elcaro is Owned {
    struct Request {
        string scriptCID;
        string scriptFunction;
        string scriptFunctionInput;
        address outputContract;
        string outputMethod;
        bool stdoutCID;
        bool stderrCID;
        uint block;
    }

    // events
    event onRequest(address node_account, uint256 request_hash);
    event onRegister(address node_account, uint256 node_count);
    event onUnregister(address node_account, uint256 node_count);

    using HitchensOrderStatisticsTreeLib for HitchensOrderStatisticsTreeLib.Tree;
    HitchensOrderStatisticsTreeLib.Tree tree;

    mapping(uint256 => Request) requests;
    mapping(address => uint256) nodes;

    constructor() {
    }

    // node management
    function register() external payable returns (bool) {
        nodes[msg.sender] += msg.value;
        emit onRegister(tx.origin, 0);

        return true;
    }

    function unregister() external returns (bool) {
        nodes[msg.sender] = 0;
        emit onUnregister(tx.origin, 0);

        return true;
    }
}
