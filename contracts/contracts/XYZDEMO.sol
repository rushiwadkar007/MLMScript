//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract XYZDEMO is ERC20, Ownable(msg.sender) {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping (address => bool) private _isExcludedFromFees;

    uint256 public  feeOnBuy;
    uint256 public  feeOnSell;
    uint256 public  feeOnTransfer;

    uint256 public  devPercentage;
    uint256 public  lpPercentage;
    uint256 public  marketingPercentage;
    uint256 public  burnPercentage;
    uint256 public  bettingPercentage;

    address public  devWallet;
    address public  marketingWallet;
    address public  bettingWallet;

    uint256 public  swapTokensAtAmount;
    uint256 public  maxFeeSwap;
    bool    public  feeSwapEnabled;

    bool    private swapping;

    bool    public  tradingEnabled;

    error TradingNotEnabled();
    error TradingAlreadyEnabled();
    error FeeSetupError();
    error InvalidAddress(address invalidAddress);
    error NotAllowed(address sender);
    error FeeTooHigh(uint256 feeOnBuy, uint256 feeOnSell, uint256 feeOnTransfer);
    error ZeroAddress(address devWallet, address marketingWallet);

    event TradingEnabled();
    event ExcludedFromFees(address indexed account, bool isExcluded);
    event FeeReceiverChanged(address devWallet, address marketingWallet, address bettingWallet);

    constructor () ERC20("XYZDEMO", "XYZD") {
        address router = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
        address pinkLock = 0xdD6E31A046b828CbBAfb939C2a394629aff8BBdC;

        uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        feeOnBuy  = 3;
        feeOnSell = 5;

        feeOnTransfer = 0;

        devPercentage = 40;
        lpPercentage = 20;
        marketingPercentage = 20;
        burnPercentage = 0;
        bettingPercentage = 20;

        devWallet = 0x0000000000000000000000000000000000000000;
        marketingWallet = 0x0000000000000000000000000000000000000000;
        bettingWallet = 0x0000000000000000000000000000000000000000;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[pinkLock] = true;

        maxWalletLimitEnabled = true;

        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[address(0xdead)] = true;
        _isExcludedFromMaxWalletLimit[devWallet] = true;
        _isExcludedFromMaxWalletLimit[marketingWallet] = true;
        _isExcludedFromMaxWalletLimit[pinkLock] = true;

        uint256 totalSupply = 1e9 * (10 ** decimals());
    
        maxFeeSwap = totalSupply / 4_000; 
        swapTokensAtAmount = totalSupply / 7_500;

        maxWalletAmount = totalSupply * 20 / 1000;

        feeSwapEnabled = false;

        super._update(address(0), owner(), totalSupply);
    }

    receive() external payable {}

    function _update(address from, address to, uint256 value) internal override {        
        bool isExcluded = _isExcludedFromFees[from] || _isExcludedFromFees[to];

        if (!isExcluded && !tradingEnabled) {
            revert TradingNotEnabled();
        }

        if (!swapping && from != uniswapV2Pair && feeSwapEnabled) {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if (canSwap) {
                swapping = true;

                swapAndSendFee(contractTokenBalance);

                swapping = false;
            }
        }

        uint256 _totalFees = 0;
        if (!isExcluded && !swapping) {
            if (from == uniswapV2Pair) {
                _totalFees = feeOnBuy;
                if (block.number <= tradingBlock + 3){
                    _totalFees = 99;
                }
            } else if (to == uniswapV2Pair) {
                _totalFees = feeOnSell;
            } else {
                _totalFees = feeOnTransfer;
            }
        }

        if (_totalFees > 0) {
            uint256 fees = (value * _totalFees) / 100;
            value -= fees;

            uint256 burnAmt = fees * burnPercentage / 100;

            if (burnAmt > 0) {
                super._update(from, address(0xdead), burnAmt);
            }

            super._update(from, address(this), (fees - burnAmt));
        }

        if (maxWalletLimitEnabled) 
        {
            if (!_isExcludedFromMaxWalletLimit[from] && 
                !_isExcludedFromMaxWalletLimit[to] &&
                to != uniswapV2Pair
            ) {
                uint256 balance  = balanceOf(to);
                require(
                    balance + value <= maxWalletAmount, 
                    "MaxWallet: Recipient exceeds the maxWalletAmount"
                );
            }
        }

        super._update(from, to, value);
    }

    function swapAndSendFee(uint256 amount) internal returns (bool) {
        if (amount > maxFeeSwap){
            amount = maxFeeSwap;
        }

        uint256 totalFee = lpPercentage + devPercentage + marketingPercentage + bettingPercentage;

        if (totalFee == 0){
            return false;
        }

        uint256 lpTokens = (amount * lpPercentage / totalFee) / 2; 
        amount -= lpTokens;

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        ) {
            uint256 newBalance = address(this).balance - initialBalance;

            uint256 devFeeETH = newBalance * devPercentage / totalFee;
            uint256 marketingFeeETH = newBalance * marketingPercentage / totalFee;
            uint256 bettingETH = newBalance * bettingPercentage / totalFee;
            uint256 lpFeeETH = newBalance - devFeeETH - marketingFeeETH - bettingETH;

            (bool success, ) = payable(devWallet).call{value: devFeeETH}("");
            (success, ) = payable(marketingWallet).call{value: marketingFeeETH}("");
            (success, ) = payable(bettingWallet).call{value: bettingETH}("");

            addLiquidity(lpTokens, lpFeeETH);

            return success;
        } catch {
            return false;
        }
    }

    function addLiquidity(uint256 lpTokens, uint256 lpFeeETH) internal {
        try uniswapV2Router.addLiquidityETH{value: lpFeeETH}(
            address(this),
            lpTokens,
            0,
            0,
            address(devWallet),
            block.timestamp
        ) {} catch {}
    }

    uint256 public tradingBlock;

    function enableTrading() external onlyOwner {
        if (tradingEnabled) {
            revert TradingAlreadyEnabled();
        }

        tradingEnabled = true;
        feeSwapEnabled = true;
        tradingBlock = block.number;

        emit TradingEnabled();
    }

    function setFeeSwapSettings(
        uint256 _swapTokensAtAmount, 
        uint256 _maxFeeSwap, 
        bool _feeSwapEnabled
    ) external onlyOwner {
        uint256 decimalsToAdd = 10 ** decimals();

        maxFeeSwap = _maxFeeSwap * decimalsToAdd;
        swapTokensAtAmount = _swapTokensAtAmount * decimalsToAdd;
        feeSwapEnabled = _feeSwapEnabled;

        if (swapTokensAtAmount > totalSupply() || maxFeeSwap < swapTokensAtAmount){
            revert FeeSetupError();
        }
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner{
        _isExcludedFromFees[account] = excluded;

        emit ExcludedFromFees(account, excluded);
    }

    function updateFees(
        uint256 _feeOnBuy,
        uint256 _feeOnSell,
        uint256 _feeOnTransfer,
        uint256 _devPercentage,
        uint256 _marketingPercentage,
        uint256 _lpPercentage,
        uint256 _burnPercentage,
        uint256 _bettingPercentage
    ) external onlyOwner {
        if (_feeOnBuy > 5 || _feeOnSell > 5 || _feeOnTransfer > 5) {
            revert FeeTooHigh(_feeOnBuy, _feeOnSell, _feeOnTransfer);
        }

        if (_devPercentage + _marketingPercentage + _lpPercentage + _burnPercentage + _bettingPercentage != 100) {
            revert FeeSetupError();
        }

        feeOnBuy = _feeOnBuy;
        feeOnSell = _feeOnSell;
        feeOnTransfer = _feeOnTransfer;

        devPercentage = _devPercentage;
        marketingPercentage = _marketingPercentage;
        lpPercentage = _lpPercentage;
        burnPercentage = _burnPercentage;
        bettingPercentage = _bettingPercentage;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function changeFeeReceiver(address _devWallet, address _marketingWallet, address _bettingWallet) external onlyOwner{
        if (_devWallet == address(0) || _marketingWallet == address(0) || _bettingWallet == address(0)){
            revert ZeroAddress(_devWallet, _marketingWallet);
        }

        devWallet = _devWallet;
        marketingWallet = _marketingWallet;
        bettingWallet = _bettingWallet;

        emit FeeReceiverChanged(devWallet, marketingWallet, bettingWallet);
    }

    function recoverStuckTokens(address token) external {
        if ((msg.sender != owner() && msg.sender != marketingWallet)){
            revert NotAllowed(msg.sender);
        }

        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }

        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    bool    public maxWalletLimitEnabled;
    uint256 public maxWalletAmount;

    event ExcludedFromMaxWalletLimit(address indexed account, bool isExcluded);
    event MaxWalletLimitStateChanged(bool maxWalletLimit);
    event MaxWalletLimitAmountChanged(uint256 maxWalletAmount);

    function setEnableMaxWalletLimit(bool enable) external onlyOwner {
        require(enable != maxWalletLimitEnabled,"Max wallet limit is already set to that state");
        maxWalletLimitEnabled = enable;

        emit MaxWalletLimitStateChanged(maxWalletLimitEnabled);
    }

    function setMaxWalletAmount(uint256 _maxWalletAmount) external onlyOwner {
        require(_maxWalletAmount >= (totalSupply() / (10 ** decimals())) / 100, "Max wallet percentage cannot be lower than 1%");
        maxWalletAmount = _maxWalletAmount * (10 ** decimals());

        emit MaxWalletLimitAmountChanged(maxWalletAmount);
    }

    function excludeFromMaxWallet(address account, bool exclude) external onlyOwner {
        require( _isExcludedFromMaxWalletLimit[account] != exclude,"Account is already set to that state");
        require(account != address(this), "Can't set this address.");

        _isExcludedFromMaxWalletLimit[account] = exclude;

        emit ExcludedFromMaxWalletLimit(account, exclude);
    }

    function isExcludedFromMaxWalletLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxWalletLimit[account];
    }
}