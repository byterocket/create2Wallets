// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IFetchFunds {
    function fetchTo(address receiver, address[] calldata tokens) external;
}

interface IERC20 {
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
}

/**
 * @title TransferWithContext contract
 *
 * @dev ...
 *
 * @author byterocket
 */
abstract contract TransferWithContext {

    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by Context's owner.
    error NotContextOwner(bytes32 ctx);

    /// @notice Contract creation failed.
    error ContractCreationFailed();

    //--------------------------------------------------------------------------
    // Modifiers

    /// @dev Modifier to guarantee only the context's owner can fetch funds
    ///      associated with given context.
    modifier onlyContextOwner(bytes32 ctx) {
        if (_contextOwners[ctx] != msg.sender) {
            revert NotContextOwner(ctx);
        }
        _;
    }

    //--------------------------------------------------------------------------
    // Constants

    /// @dev The FetchFunds' bytecode.
    bytes private constant BYTECODE = type(FetchFunds).creationCode;

    /// @dev The FetchFunds' bytecode hash.
    bytes32 private constant BYTECODE_HASH
        = keccak256(abi.encodePacked(BYTECODE));

    //--------------------------------------------------------------------------
    // Storage

    /// @dev Mapping of contexts to context's owners.
    mapping(bytes32 => address) private _contextOwners;

    //--------------------------------------------------------------------------
    // Public Mutating Functions

    /// @notice Transfers ETH and tokens associated with context to recipient.
    /// @dev Only callable by context's owner.
    /// @param ctx The context for the contract to fetch funds for.
    /// @param recipient The address to send the funds to.
    /// @param tokens Array of ERC20 token addresses to rescue.
    function fetchFundsWithContextTo(
        bytes32 ctx,
        address recipient,
        address[] calldata tokens
    ) external onlyContextOwner(ctx) {
        _fetchFundsWithContextTo(ctx, recipient, tokens);
    }

    /// @notice Transfers ETH and tokens associated with context to msg.sender.
    /// @dev Only callable by context's owner.
    /// @param ctx The context for the contract to fetch funds for.
    /// @param tokens Array of ERC20 token addresses to rescue.
    function fetchFundsWithContext(
        bytes32 ctx,
        address[] calldata tokens
    ) external onlyContextOwner(ctx) {
        _fetchFundsWithContextTo(ctx, msg.sender, tokens);
    }

    /// @notice Claims ownership of a context for msg.sender and returns the
    ///         context's address.
    /// @param ctx The context to claim ownership of.
    /// @return True if claim succeeded, false otherwise.
    /// @return The address of the contract for given context if context claim
    ///         succeeded, zero address otherwise.
    function claimContextAndReturnAddress(bytes32 ctx)
        external
        returns (bool, address)
    {
        address ctxOwner = _contextOwners[ctx];

        if (ctxOwner != address(0) && ctxOwner != msg.sender) {
            return (false, address(0));
        }

        if (ctxOwner == address(0)) {
            _contextOwners[ctx] = msg.sender;
        }

        return (true, _computeAddressWithContext(ctx));
    }

    //--------------------------------------------------------------------------
    // Public View Functions

    function getAddressWithContext(bytes32 ctx)
        external
        view
        returns (address)
    {
        return _computeAddressWithContext(ctx);
    }

    function getContextOwner(bytes32 ctx) external view returns (address) {
        return _contextOwners[ctx];
    }

    function contextAvailable(bytes32 ctx) external view returns (bool) {
        return _contextOwners[ctx] == address(0);
    }

    //--------------------------------------------------------------------------
    // Private Functions

    function _fetchFundsWithContextTo(
        bytes32 ctx,
        address recipient,
        address[] calldata tokens
    ) private {
        address fetcher = _deployContext(ctx);
        IFetchFunds(fetcher).fetchTo(recipient, tokens);
    }

    /// @dev Deploys a new RescueFunds contract with given salt and returns
    ///      the contract's address.
    function _deployContext(bytes32 ctx) private returns (address) {
        address fetcher;
        bytes memory bytecode = BYTECODE; // @todo Use storage variable and offset?

        assembly {
            fetcher := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                ctx
            )
        }

        if (fetcher == address(0)) {
            revert ContractCreationFailed();
        }

        return fetcher;
    }

    /// @dev Returns the address a newly FetchFunds' contract will be stored at
    ///      for given context.
    /// @dev For more info see https://eips.ethereum.org/EIPS/eip-1014#specification.
    function _computeAddressWithContext(bytes32 ctx)
        private
        view
        returns (address)
    {
        bytes32 data =
            keccak256(
                abi.encodePacked(
                    bytes1(0xff),
                    address(this), // Deployer address
                    ctx,
                    BYTECODE_HASH
                )
            );

        return address(uint160(uint(data)));
    }

}

contract FetchFunds {

    function fetchTo(address recipient, address[] calldata tokens) external {
        address token;
        uint balance;

        // Send tokens to receiver.
        uint len = tokens.length;
        for (uint i; i < len; ) {
            token = tokens[i];
            balance = IERC20(token).balanceOf(address(this));

            IERC20(token).transfer(recipient, balance);

            unchecked { ++i; }
        }

        selfdestruct(payable(recipient));
    }

}
