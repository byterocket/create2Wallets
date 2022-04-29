// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "../interfaces/_external/IERC20.sol";

import {IERC20ContextWallet} from "../interfaces/IERC20ContextWallet.sol";
import {
    IERC20ContextWalletManager
} from "../interfaces/IERC20ContextWalletManager.sol";

import {ERC20ContextWallet} from "./ERC20ContextWallet.sol";

contract ERC20ContextWalletManager is IERC20ContextWalletManager {

    //--------------------------------------------------------------------------
    // Errors

    error WalletDeploymentFailed();

    //--------------------------------------------------------------------------
    // Modifiers

    modifier onlyContextOwner(bytes32 ctx) {
        if (_owners[ctx] != msg.sender) {
            revert();
        }
        _;
    }

    //--------------------------------------------------------------------------
    // Constants

    bytes constant private BYTECODE = type(ERC20ContextWallet).creationCode;
    bytes32 constant private BYTECODE_HASH
        = keccak256(abi.encodePacked(BYTECODE));

    //--------------------------------------------------------------------------
    // Storage

    mapping(bytes32 => address) internal _owners;

    //--------------------------------------------------------------------------
    // Public View Functions

    function walletIdentifier(bytes32 ctx) external view returns (string memory) {
        // Identifier = chainId + ":" + address(this) + ":" + string(ctx)?
    }

    function walletAddressAndOwner(bytes32 ctx)
        external
        view
        returns (address)
    {
        return _computeWalletAddress(ctx);
    }

    function owner(bytes32 ctx) external view returns (address) {
        return _owners[ctx];
    }

    function claimOwnership(bytes32 ctx) external {
        // Use modifier.
        _owners[ctx] = msg.sender;
    }

    function walletAvailable(bytes32 ctx) external view returns (bool) {
        return _owners[ctx] == address(0);
    }

    function balanceOf(bytes32 ctx, address erc20) external view returns (uint) {
        address wallet = _computeWalletAddress(ctx);

        return IERC20(erc20).balanceOf(wallet);
    }

    //--------------------------------------------------------------------------
    // onlyContextOwner Mutating Functions

    function executeTxBatch(
        bytes32 ctx
        /** array of txs */
        /** array of args */
    ) external onlyContextOwner(ctx) {
        //address wallet = _deployWallet(ctx);

        // for (tx in txs) {
        //   executeTx(tx.params);
        // }
    }

    function transfer(bytes32 ctx, address erc20, address to, uint amount)
        external
        onlyContextOwner(ctx)
    {
        address wallet = _deployWallet(ctx);

        IERC20ContextWallet(wallet).transfer(erc20, to, amount);
    }

    function transferFrom(bytes32 ctx, address erc20, address from, address to, uint amount)
        external
        onlyContextOwner(ctx)
    {
        address wallet = _deployWallet(ctx);

        IERC20ContextWallet(wallet).transferFrom(erc20, from, to, amount);
    }

    function approve(bytes32 ctx, address erc20, address spender, uint amount)
        external
        onlyContextOwner(ctx)
    {
        address wallet = _deployWallet(ctx);

        IERC20ContextWallet(wallet).approve(erc20, spender, amount);
    }

    //--------------------------------------------------------------------------
    // Internal Functions

    function _computeWalletAddress(bytes32 ctx)
        internal
        view
        returns (address)
    {
        address deployer = address(this);
        bytes32 bytecodeHash = BYTECODE_HASH; // Use storage and assembly offset.

        bytes32 data =
            keccak256(
                abi.encodePacked(
                    bytes1(0xff),
                    deployer,
                    ctx,
                    bytecodeHash
                )
            );

        return address(uint160(uint(data)));
    }

    function _deployWallet(bytes32 ctx)
        internal
        returns (address)
    {
        address wallet;
        bytes memory bytecode = BYTECODE; // Use storage and assembly offset.

        assembly {
            wallet := create2(0, add(bytecode, 0x20), mload(bytecode), ctx)
        }

        if (wallet == address(0)) {
            revert WalletDeploymentFailed();
        }

        return wallet;
    }


}
