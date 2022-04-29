// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20ContextWallet {

    function transfer(address erc20, address to, uint amount) external;

    function transferFrom(address erc20, address from, address to, uint amount) external;

    function approve(address erc20, address spender, uint amount) external;
}
