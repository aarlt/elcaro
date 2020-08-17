// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IElcaro {
    // node management
    function register() external payable returns (bool);
    function unregister() external returns (bool);
    function nodeCount() external view returns (uint256);
    function isRegistered(address _id) external view returns (bool);

    // requests
    function request(string memory _function, bytes calldata _arguments, address _contract, string memory _callback) external payable returns (bool);
    function request_n(uint256 count, string memory _function, bytes calldata _arguments, address _contract, string memory _callback) external payable returns (bool);

    // responses
    function response(bytes memory _request, bytes memory _response, string memory stdout, string memory stderr) external returns (bool);
}
