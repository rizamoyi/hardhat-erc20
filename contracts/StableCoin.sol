// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";
import {Oracle} from "./Oracle.sol";

contract StableCoin is ERC20 {
    DepositorCoin public depositorCoin;
    Oracle public oracle;

    uint256 public feeRatePercentage;
    uint256 public constant INITIAL_COLLATERAL_RATIO_PERCENTAGE = 10;

    constructor(uint256 _feeRatePercantage, Oracle _oracle)
        ERC20("Stablecoin", "STC")
    {
        feeRatePercentage = _feeRatePercantage;
        oracle = _oracle;
    }

    function mint() external payable {
        uint256 fee = _getFee(msg.value);
        uint256 remainingEth = msg.value - fee;

        uint256 mintStableCoinAmount = msg.value * oracle.getPrice();
        _mint(msg.sender, mintStableCoinAmount);
    }

    function burn(uint256 burnStableCoinAmount) external {
        _burn(msg.sender, burnStableCoinAmount);

        uint256 refundingEth = burnStableCoinAmount / oracle.getPrice();
        uint256 fee = _getFee(refundingEth);
        uint256 remainingRefundingEth = refundingEth - fee;

        (bool, success, ) = msg.sender.call{value: remainingRefundingEth}("");
        require(success, "STC: Burn refund transaction failed");
    }

    function _getFee(uint256 ethAmount) private view returns (uint256) {
        bool hasDepositors = address(depositorCoin) != address(0) &&
            depositorCoin.totalSupply() > 0;

        if (!hasDepositors) {
            return 0;
        }
        return (feeRatePercentage * ethAmount) / 100;
    }

    function depositCollateralBuffer() external payable {
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractInUsd();

        if (deficitOrSurplusInUsd <= 0) {
            uint256 deficitInUsd = uint256(deficitOrSurplusInUsd * -1);
            uint256 usdInEthPrice = oracle.getPrice();
            uint256 deficitInEth = deficitInUsd / usdInEthPrice;

            uint256 requiredInitialSurplusInUsd = (INITIAL_COLLATERAL_RATIO_PERCENTAGE *
                    totalSupply) / 100;
            uint256 requiredInitialSurplusInEth = requiredInitialSurplusInUsd /
                usdInEthPrice;

            require(
                msg.value >= deficitInEth + requiredInitialSurplusInEth,
                "STC: Initial Collateral ratio not met"
            );

            uint256 newInitialSurplusInEth = msg.value - deficitInEth;
            uint256 newInitialSurplusInUsd = newInitialSurplusInEth *
                usdInEthPrice;

            depositorCoin = new DepositorCoin();
            uint256 mintDepostorCoinAmount = newInitialSurplusInUsd;
            depositorCoin.mint(msg.sender, mintDepostorCoinAmount);
            return;
        }

        uint256 surplusInUsd = uint256(deficitOrSurplusInUsd);
        uint256 dpcInUsdPrice = _getDPCinUsdPrice(surplusInUsd);
        uint256 mintDepositorCoinAmount = ((msg.value * dpcInUsdPrice) /
            oracle.getPrice());

        depositorCoin.mint(msg.sender, mintDepositorCoinAmount);
    }

    function _getDeficitOrSurplusInContractInUsd()
        private
        view
        returns (int256)
    {
        uint256 ethContractBalanceInUsd = (address(this).balance - msg.value) *
            oracle.getPrice();
        uint256 totalStableCoinBalanceInUsd = totalSupply;
        int256 deficitOrSurplus = int256(ethContractBalanceInUsd) -
            int256(totalStableCoinBalanceInUsd);

        return deficitOrSurplus;
    }

    function _getDPCinUsdPrice(uint256 surplusInUsd)
        private
        view
        returns (uint256)
    {
        return depositorCoin.totalSupply() / surplusInUsd;
    }
}
