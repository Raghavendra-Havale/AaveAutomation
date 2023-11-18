// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the ERC20 interface
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface AaveInterface {
    struct AaveV3UserData {
        uint256 totalCollateralBase;
        uint256 totalBorrowsBase;
        uint256 availableBorrowsBase;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
    }

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface IAutomate {
    function getFeeDetails() external view returns (uint256 fee, address feeToken);
    function gelato() external view returns (address);
}

contract AaveCollateralManager {
    AaveInterface public aave;
    IAutomate public automate;

    mapping(address => bool) public whitelisted;

    constructor(address _lendingPoolAddress, address _automateAddress) {
        aave = AaveInterface(_lendingPoolAddress);
        automate = IAutomate(_automateAddress);
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function addToWhitelist(address _address) public {
        whitelisted[_address] = true;
    }

    function addCollateral(address asset, uint256 amount, address user) external onlyWhitelisted {
    
        uint256 allowance = IERC20(asset).allowance(user, address(this));
        require(allowance >= amount, "Insufficient allowance");
        IERC20(asset).transferFrom(user, address(this), amount);
        IERC20(asset).approve(address(aave), amount);
        aave.supply(asset, amount, user, 0);
        }



    function checkHealthFactor(address user) external view returns (uint256 healthFactor) {
        (,, , , , healthFactor) = aave.getUserAccountData(user);
    }
}
