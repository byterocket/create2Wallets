// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20ContextWalletManager {

    function walletIdentifier(bytes32 context) external view returns (string memory);

    function balanceOf(bytes32 context, address erc20) external view returns (uint);

    function owner(bytes32 context) external view returns (address);

    function claimOwnership(bytes32 context) external;

    function walletAvailable(bytes32 context) external view returns (bool);

    function transfer(bytes32 context, address erc20, address to, uint amount) external;

    function transferFrom(bytes32 context, address erc20, address from, address to, uint amount) external;

    function approve(bytes32 context, address erc20, address spender, uint amount) external;
}
