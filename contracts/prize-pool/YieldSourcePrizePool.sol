// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IYieldSource.sol";

import "./PrizePool.sol";


contract YieldSourcePrizePool is PrizePool {
    using SafeERC20 for IERC20;
    using Address for address;

        struct userShares {
        uint amountDeposited;
        uint userShare;
    }

    mapping(address=>userShares) public User;


    IYieldSource public immutable yieldSource;


    event Deployed(address indexed yieldSource);


    event Swept(uint256 amount);


    constructor(address _owner, IYieldSource _yieldSource) PrizePool(_owner) {
        require(
            address(_yieldSource) != address(0),
            "YieldSourcePrizePool/yield-source-not-zero-address"
        );

        yieldSource = _yieldSource;


        (bool succeeded, bytes memory data) = address(_yieldSource).staticcall(
            abi.encodePacked(_yieldSource.depositToken.selector)
        );
        address resultingAddress;
        if (data.length > 0) {
            resultingAddress = abi.decode(data, (address));
        }
        require(succeeded && resultingAddress != address(0), "YieldSourcePrizePool/invalid-yield-source");

        emit Deployed(address(_yieldSource));
    }


    function sweep() external nonReentrant onlyOwner {
        uint256 balance = _token().balanceOf(address(this));
        _supply(balance);

        emit Swept(balance);
    }


    function _canAwardExternal(address _externalToken) internal view override returns (bool) {
        IYieldSource _yieldSource = yieldSource;
        return (
            _externalToken != address(_yieldSource) &&
            _externalToken != _yieldSource.depositToken()
        );
    }


    function _balance() internal override returns (uint256) {
        return yieldSource.balanceOfToken(address(this));
    }

    function _token() internal view override returns (IERC20) {
        return IERC20(yieldSource.depositToken());
    }

    function _supply(uint256 _mintAmount) internal override {
        _token().safeIncreaseAllowance(address(yieldSource), _mintAmount);
        yieldSource.supplyTokenTo(_mintAmount, address(this));
    }


    function _redeem(uint256 _redeemAmount) internal override returns (uint256) {
        return yieldSource.redeemToken(_redeemAmount);
    }


    function depositTo(address _to, uint256 _amount)
        external
        override
        nonReentrant
        canAddLiquidity(_amount)
    {
        _depositTo(msg.sender, _to, _amount);
    }

    function _depositTo(address _operator, address _to, uint256 _amount) internal
    {
        require(_canDeposit(_to, _amount), "PrizePool/exceeds-balance-cap");

        ITicket _ticket = ticket;
         uint totalTicketAmount;
         uint tickets;
         uint totalTokenAmount = balanceOfYieldSource();

        if(totalTokenAmount>0)
        {   
        totalTicketAmount = _ticket.totalSupply();
         totalTicketAmount;
        tickets = (totalTicketAmount  * _amount /totalTokenAmount);

        _token().safeTransferFrom(_operator, address(this), _amount);

        _mint(_to, tickets, _ticket);
        _supply(_amount);

        totalTokenAmount+= _amount;

           User[_to] = userShares({
            amountDeposited: User[_to].amountDeposited+ _amount,
            userShare: User[_to].userShare+tickets
        });
        }
        else {
        _token().safeTransferFrom(_operator, address(this), _amount);

        _mint(_to, _amount, _ticket);
        _supply(_amount);

        totalTokenAmount+= _amount;

           User[_to] = userShares({
            amountDeposited: User[_to].amountDeposited+ _amount,
            userShare: User[_to].userShare+_amount
        });
        }
        emit Deposited(_operator, _to, _ticket, _amount);
    }

 
    

    /// @inheritdoc IPrizePool
    function withdrawFrom(address _from, uint256 _amount)
        external
        override
        nonReentrant
        returns (uint256)
    {   
        ITicket _ticket = ticket;
        uint totalTokenAmount = balanceOfYieldSource();
        uint totalTicketAmount = _ticket.totalSupply();
        uint tokenAmount = (totalTokenAmount * _amount / totalTicketAmount);

        // burn the tickets
        _ticket.controllerBurnFrom(msg.sender, _from, _amount);

        // redeem the tickets
        uint256 _redeemed = _redeem(tokenAmount);

        _token().safeTransfer(_from, _redeemed);

        User[_from] = userShares({
        amountDeposited: User[_from].amountDeposited,
        userShare: User[_from].userShare-_amount
        });

        emit Withdrawal(msg.sender, _from, _ticket, _amount, _redeemed);

        return _redeemed;
    }

    function balanceOfYieldSource() public returns(uint) {
        return yieldSource.balanceOfToken(address(yieldSource));
    }
}
