// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @title Commit-Reveal Wallet
 *
 * @dev A one-time wallet based on a commit-reveal scheme.
 *
 *
 * @author byterocket
 */
contract CommitRevealWallet {

    bytes constant private BYTECODE = type(Wallet).creationCode;

    bytes32 constant private BYTECODE_HASH = keccak256(BYTECODE);

    // Note to only use this function through a trusted, i.e. self-hosted, node!
    function computeAddress(bytes32 key) external view returns (address) {
        bytes32 keyHash = keccak256(abi.encode(key));

        bytes32 data =
            keccak256(
                abi.encodePacked(
                    bytes1(0xff),
                    address(this), // Deployer address
                    keyHash,
                    BYTECODE_HASH
                )
            );

        return address(uint160(uint(data)));
    }

    function useWallet(bytes32 key, address to, bytes calldata data)
        external
    {
        bytes32 keyHash = keccak256(abi.encode(key));

        // Deploy wallet.
        address wallet;
        bytes memory bytecode = BYTECODE;

        assembly {
            wallet := create2(0, add(bytecode, 0x20), mload(bytecode), keyHash)
        }

        assert(wallet != address(0));

        // Execute tx.
        IWallet(wallet).executeTx(to, data);
    }

}

interface IWallet {
    function executeTx(address to, bytes calldata data) external;
}

contract Wallet {

    function executeTx(address to, bytes calldata data) external {
        // Note that it's not checked whether the tx succeeded.
        // The key is revealed anyway. Make sure the tx will go through!
        to.call(data);

        // Note to make sure that address to either is payable or no ETH held
        // in contract.
        selfdestruct(payable(to));
    }

}
