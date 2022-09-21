// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

import "../external/compound/ICompLike.sol";
import "../interfaces/IPrizePool.sol";
import "../interfaces/ITicket.sol";


abstract contract PrizePool is IPrizePool, Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using ERC165Checker for address;



    ITicket internal ticket;

    address internal prizeStrategy;

    uint256 internal balanceCap;

    uint256 internal liquidityCap;

    uint256 internal _currentAwardBalance;




    modifier onlyPrizeStrategy() {
        require(msg.sender == prizeStrategy, "PrizePool/only-prizeStrategy");
        _;
    }

 
    modifier canAddLiquidity(uint256 _amount) {
        require(_canAddLiquidity(_amount), "PrizePool/exceeds-liquidity-cap");
        _;
    }

    constructor(address _owner) Ownable(_owner) ReentrancyGuard() {
        _setLiquidityCap(type(uint256).max);
    }


    function balance() external override returns (uint256) {
        return _balance();
    }

    


    function isControlled(ITicket _controlledToken) external view override returns (bool) {
        return _isControlled(_controlledToken);
    }

    function getAccountedBalance() external view override returns (uint256) {
        return _ticketTotalSupply();
    }


    function getBalanceCap() external view override returns (uint256) {
        return balanceCap;
    }

    function getLiquidityCap() external view override returns (uint256) {
        return liquidityCap;
    }


    function getTicket() external view override returns (ITicket) {
        return ticket;
    }


    function getPrizeStrategy() external view override returns (address) {
        return prizeStrategy;
    }


    function getToken() external view override returns (address) {
        return address(_token());
    }

    /// @inheritdoc IPrizePool
    // function captureAwardBalance() external override nonReentrant returns (uint256) {
    //     uint256 ticketTotalSupply = _ticketTotalSupply();
    //     uint256 currentAwardBalance = _currentAwardBalance;

    //     // it's possible for the balance to be slightly less due to rounding errors in the underlying yield source
    //     uint256 currentBalance = _balance();
    //     uint256 totalInterest = (currentBalance > ticketTotalSupply)
    //         ? currentBalance - ticketTotalSupply
    //         : 0;

    //     uint256 unaccountedPrizeBalance = (totalInterest > currentAwardBalance)
    //         ? totalInterest - currentAwardBalance
    //         : 0;

    //     if (unaccountedPrizeBalance > 0) {
    //         currentAwardBalance = totalInterest;
    //         _currentAwardBalance = currentAwardBalance;

    //         emit AwardCaptured(unaccountedPrizeBalance);
    //     }

    //     return currentAwardBalance;
    // }

    /// @inheritdoc IPrizePool
    

    // /// @inheritdoc IPrizePool
    // function depositToAndDelegate(address _to, uint256 _amount, address _delegate)
    //     external
    //     override
    //     nonReentrant
    //     canAddLiquidity(_amount)
    // {
    //     _depositTo(msg.sender, _to, _amount);
    //     ticket.controllerDelegateFor(msg.sender, _delegate);
    // }

    /// @notice Transfers tokens in from one user and mints tickets to another
    /// @notice _operator The user to transfer tokens from
    /// @notice _to The user to mint tickets to
    /// @notice _amount The amount to transfer and mint
    

    // /// @inheritdoc IPrizePool
    // function award(address _to, uint256 _amount) external override onlyPrizeStrategy {
    //     if (_amount == 0) {
    //         return;
    //     }

    //     uint256 currentAwardBalance = _currentAwardBalance;

    //     require(_amount <= currentAwardBalance, "PrizePool/award-exceeds-avail");

    //     unchecked {
    //         _currentAwardBalance = currentAwardBalance - _amount;
    //     }

    //     ITicket _ticket = ticket;

    //     _mint(_to, _amount, _ticket);

    //     emit Awarded(_to, _ticket, _amount);
    // }

    // /// @inheritdoc IPrizePool
    // function transferExternalERC20(
    //     address _to,
    //     address _externalToken,
    //     uint256 _amount
    // ) external override onlyPrizeStrategy {
    //     if (_transferOut(_to, _externalToken, _amount)) {
    //         emit TransferredExternalERC20(_to, _externalToken, _amount);
    //     }
    // }

    // /// @inheritdoc IPrizePool
    // function awardExternalERC20(
    //     address _to,
    //     address _externalToken,
    //     uint256 _amount
    // ) external override onlyPrizeStrategy {
    //     if (_transferOut(_to, _externalToken, _amount)) {
    //         emit AwardedExternalERC20(_to, _externalToken, _amount);
    //     }
    // }

    // /// @inheritdoc IPrizePool
    // function awardExternalERC721(
    //     address _to,
    //     address _externalToken,
    //     uint256[] calldata _tokenIds
    // ) external override onlyPrizeStrategy {
    //     require(_canAwardExternal(_externalToken), "PrizePool/invalid-external-token");

    //     if (_tokenIds.length == 0) {
    //         return;
    //     }

    //     uint256[] memory _awardedTokenIds = new uint256[](_tokenIds.length); 
    //     bool hasAwardedTokenIds;

    //     for (uint256 i = 0; i < _tokenIds.length; i++) {
    //         try IERC721(_externalToken).safeTransferFrom(address(this), _to, _tokenIds[i]) {
    //             hasAwardedTokenIds = true;
    //             _awardedTokenIds[i] = _tokenIds[i];
    //         } catch (
    //             bytes memory error
    //         ) {
    //             emit ErrorAwardingExternalERC721(error);
    //         }
    //     }
    //     if (hasAwardedTokenIds) { 
    //         emit AwardedExternalERC721(_to, _externalToken, _awardedTokenIds);
    //     }
    // }

    /// @inheritdoc IPrizePool
    function setBalanceCap(uint256 _balanceCap) external override onlyOwner returns (bool) {
        _setBalanceCap(_balanceCap);
        return true;
    }

    /// @inheritdoc IPrizePool
    function setLiquidityCap(uint256 _liquidityCap) external override onlyOwner {
        _setLiquidityCap(_liquidityCap);
    }

    /// @inheritdoc IPrizePool
    function setTicket(ITicket _ticket) external override onlyOwner returns (bool) {
        require(address(_ticket) != address(0), "PrizePool/ticket-not-zero-address");
        require(address(ticket) == address(0), "PrizePool/ticket-already-set");

        ticket = _ticket;

        emit TicketSet(_ticket);

        _setBalanceCap(type(uint256).max);

        return true;
    }

    /// @inheritdoc IPrizePool
    function setPrizeStrategy(address _prizeStrategy) external override onlyOwner {
        _setPrizeStrategy(_prizeStrategy);
    }

    // /// @inheritdoc IPrizePool
    // function compLikeDelegate(ICompLike _compLike, address _to) external override onlyOwner {
    //     if (_compLike.balanceOf(address(this)) > 0) {
    //         _compLike.delegate(_to);
    //     }
    // }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /* ============ Internal Functions ============ */

    /// @notice Transfer out `amount` of `externalToken` to recipient `to`
    /// @dev Only awardable `externalToken` can be transferred out
    /// @param _to Recipient address
    /// @param _externalToken Address of the external asset token being transferred
    /// @param _amount Amount of external assets to be transferred
    /// @return True if transfer is successful
    function _transferOut(
        address _to,
        address _externalToken,
        uint256 _amount
    ) internal returns (bool) {
        require(_canAwardExternal(_externalToken), "PrizePool/invalid-external-token");

        if (_amount == 0) {
            return false;
        }

        IERC20(_externalToken).safeTransfer(_to, _amount);

        return true;
    }

    /// @notice Called to mint controlled tokens.  Ensures that token listener callbacks are fired.
    /// @param _to The user who is receiving the tokens
    /// @param _amount The amount of tokens they are receiving
    /// @param _controlledToken The token that is going to be minted
    function _mint(
        address _to,
        uint256 _amount,
        ITicket _controlledToken
    ) internal {
        _controlledToken.controllerMint(_to, _amount);
    }

    /// @dev Checks if `user` can deposit in the Prize Pool based on the current balance cap.
    /// @param _user Address of the user depositing.
    /// @param _amount The amount of tokens to be deposited into the Prize Pool.
    /// @return True if the Prize Pool can receive the specified `amount` of tokens.
    function _canDeposit(address _user, uint256 _amount) internal view returns (bool) {
        uint256 _balanceCap = balanceCap;

        if (_balanceCap == type(uint256).max) return true;

        return (ticket.balanceOf(_user) + _amount <= _balanceCap);
    }

    /// @dev Checks if the Prize Pool can receive liquidity based on the current cap
    /// @param _amount The amount of liquidity to be added to the Prize Pool
    /// @return True if the Prize Pool can receive the specified amount of liquidity
    function _canAddLiquidity(uint256 _amount) internal view returns (bool) {
        uint256 _liquidityCap = liquidityCap;
        if (_liquidityCap == type(uint256).max) return true;
        return (_ticketTotalSupply() + _amount <= _liquidityCap);
    }

    /// @dev Checks if a specific token is controlled by the Prize Pool
    /// @param _controlledToken The address of the token to check
    /// @return True if the token is a controlled token, false otherwise
    function _isControlled(ITicket _controlledToken) internal view returns (bool) {
        return (ticket == _controlledToken);
    }

    /// @notice Allows the owner to set a balance cap per `token` for the pool.
    /// @param _balanceCap New balance cap.
    function _setBalanceCap(uint256 _balanceCap) internal {
        balanceCap = _balanceCap;
        emit BalanceCapSet(_balanceCap);
    }

    /// @notice Allows the owner to set a liquidity cap for the pool
    /// @param _liquidityCap New liquidity cap
    function _setLiquidityCap(uint256 _liquidityCap) internal {
        liquidityCap = _liquidityCap;
        emit LiquidityCapSet(_liquidityCap);
    }

    /// @notice Sets the prize strategy of the prize pool.  Only callable by the owner.
    /// @param _prizeStrategy The new prize strategy
    function _setPrizeStrategy(address _prizeStrategy) internal {
        require(_prizeStrategy != address(0), "PrizePool/prizeStrategy-not-zero");

        prizeStrategy = _prizeStrategy;

        emit PrizeStrategySet(_prizeStrategy);
    }

    /// @notice The current total of tickets.
    /// @return Ticket total supply.
    function _ticketTotalSupply() internal view returns (uint256) {
        return ticket.totalSupply();
    }

    /// @dev Gets the current time as represented by the current block
    /// @return The timestamp of the current block
    function _currentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /* ============ Abstract Contract Implementatiton ============ */

    /// @notice Determines whether the passed token can be transferred out as an external award.
    /// @dev Different yield sources will hold the deposits as another kind of token: such a Compound's cToken.  The
    /// prize strategy should not be allowed to move those tokens.
    /// @param _externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function _canAwardExternal(address _externalToken) internal view virtual returns (bool);

    /// @notice Returns the ERC20 asset token used for deposits.
    /// @return The ERC20 asset token
    function _token() internal view virtual returns (IERC20);

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens
    function _balance() internal virtual returns (uint256);

    /// @notice Supplies asset tokens to the yield source.
    /// @param _mintAmount The amount of asset tokens to be supplied
    function _supply(uint256 _mintAmount) internal virtual;

    /// @notice Redeems asset tokens from the yield source.
    /// @param _redeemAmount The amount of yield-bearing tokens to be redeemed
    /// @return The actual amount of tokens that were redeemed.
    function _redeem(uint256 _redeemAmount) internal virtual returns (uint256);

    function depositTo(address to, uint256 amount) external virtual override;

    function withdrawFrom(address from, uint256 amount) external virtual override returns (uint256);
}
