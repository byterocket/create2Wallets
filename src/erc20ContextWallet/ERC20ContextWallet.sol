// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IERC20ContextWallet} from "../interfaces/IERC20ContextWallet.sol";

contract ERC20ContextWallet is IERC20ContextWallet {
    using SafeTransferLib for ERC20;

    modifier dieAndSendEth(address to) {
        _;
        _dieAndSendEth(to);
    }

    modifier dieWithoutSendingEth() {
        require(address(this).balance == 0);
        _;
        _dieAndSendEth(address(0));
    }

    function transferBatch(
        address[] calldata erc20s,
        address to,
        uint[] calldata amounts
    )
        external
        dieWithoutSendingEth
    {
        _transferBatch(erc20s, to, amounts);
    }

    function transferBatchAndEth(
        address[] calldata erc20s,
        address to,
        uint[] calldata amounts
    ) external dieAndSendEth(to) {
        _transferBatch(erc20s, to, amounts);
    }

    function transfer(address erc20, address to, uint amount)
        external
        dieWithoutSendingEth
    {
        ERC20(erc20).safeTransfer(to, amount);
    }

    function transferFrom(address erc20, address from, address to, uint amount)
        external
        dieWithoutSendingEth
    {
        ERC20(erc20).safeTransferFrom(from, to, amount);
    }

    function approve(address erc20, address spender, uint amount)
        external
        dieWithoutSendingEth
    {
        ERC20(erc20).safeApprove(spender, amount);
    }

    function _transferBatch(
        address[] calldata erc20s,
        address to,
        uint[] calldata amounts
    ) internal {
        uint len = erc20s.length;
        assert(len == amounts.length);

        for (uint i; i < len; ) {
            ERC20(erc20s[i]).safeTransfer(to, amounts[i]);

            unchecked { ++i; }
        }
    }

    function _dieAndSendEth(address to) private {
        selfdestruct(payable(to));
    }

}
