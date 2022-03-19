// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../../interfaces/IMasterchef.sol";
import "../../interfaces/IStrategyFish.sol";
import "../../interfaces/IUniPair.sol";
import "../../interfaces/IUniRouter02.sol";

contract StrategyShortDinochef is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public WETH; //or wmatic or w/e ya know? but round these parts we call it weth.
    address public vaultChefAddress;
    address public masterchefAddress;
    uint256 public pid;
    address public wantAddress;
    address public newWantAddress; //what we will sell earned rewards for
    address public earnedAddress;
    uint public sixtynine;

    
    address public uniRouterAddress;
   
    address public govAddress;

    uint256 public lastEarnBlock = block.number;
    uint256 public sharesTotal = 0;

    uint256 public controllerFee = 50; //used to make earn() pay for itself 0.5%
    
    uint256 public constant feeMaxTotal = 1000; //basically make sure that you dont have more than 1000 basis points of fees total, aka 10%
    uint256 public constant feeMax = 10000; // 100 = 1%

    uint256 public slippageFactor = 950; // 5% default slippage tolerance
    uint256 public constant slippageFactorUL = 995;

    //trade pathing
    address[] public earnedToWmaticPath;
    address[] public earnedToNewWantPath;
  

    constructor(
        address _WETH,
        address _vaultChefAddress,
        address _masterchefAddress,
        address _uniRouterAddress,
        uint256 _pid,
        address _wantAddress,
        address _newWantAddress,
        address _earnedAddress,
        address[] memory _earnedToWmaticPath,
        address[] memory _earnedToNewWantPath
    ) public {
        govAddress = msg.sender;
        vaultChefAddress = _vaultChefAddress;
        masterchefAddress = _masterchefAddress;
        uniRouterAddress = _uniRouterAddress;
        WETH = _WETH;

        wantAddress = _wantAddress;
        newWantAddress =_newWantAddress;
  

        pid = _pid;
        earnedAddress = _earnedAddress;

        earnedToWmaticPath = _earnedToWmaticPath;
        earnedToNewWantPath = _earnedToNewWantPath;
        sixtynine = 69;

        transferOwnership(vaultChefAddress);
        
        _resetAllowances();
    }
    
    event SetSettings(
        uint256 _controllerFee,
        uint256 _slippageFactor,
        address _uniRouterAddress
    );
    
    modifier onlyGov() {
        require(msg.sender == govAddress, "!gov");
        _;
    }
    
    function deposit(address _userAddress, uint256 _wantAmt) external onlyOwner nonReentrant whenNotPaused returns (uint256) {
        // Call must happen before transfer
        uint256 wantLockedBefore = wantLockedTotal();

        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );

        // Proper deposit amount for tokens with fees, or vaults with deposit fees
        uint256 sharesAdded = _farm();
        if (sharesTotal > 0) {
            sharesAdded = sharesAdded.mul(sharesTotal).div(wantLockedBefore);
        }
        sharesTotal = sharesTotal.add(sharesAdded);

        return sharesAdded;
    }

    function _farm() internal returns (uint256) {
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (wantAmt == 0) return 0;
        
        uint256 sharesBefore = vaultSharesTotal();
        IMasterchef(masterchefAddress).deposit(pid, wantAmt);
        uint256 sharesAfter = vaultSharesTotal();
        
        return sharesAfter.sub(sharesBefore);
    }

    function withdraw(address _userAddress, uint256 _wantAmt) external onlyOwner nonReentrant returns (uint256) {
        require(_wantAmt > 0, "_wantAmt is 0");
        
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        
        // Check if strategy has tokens from panic
        if (_wantAmt > wantAmt) {
            IMasterchef(masterchefAddress).withdraw(pid, _wantAmt.sub(wantAmt));
            wantAmt = IERC20(wantAddress).balanceOf(address(this));
        }

        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (_wantAmt > wantLockedTotal()) {
            _wantAmt = wantLockedTotal();
        }

        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal());
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);

        IERC20(wantAddress).safeTransfer(vaultChefAddress, _wantAmt);

        return sharesRemoved;
    }

function harvest(address _userAddress, uint256 _bonusAmt) external onlyOwner nonReentrant returns (uint256) {
        require(_bonusAmt > 0, "_wantAmt is 0");
        
        uint256 newWantAmt = IERC20(newWantAddress).balanceOf(address(this));
        

        if (_bonusAmt > newWantAmt) {
            _bonusAmt = newWantAmt;
        }

        uint256 bonusBefore = bonusWantLockedTotal();
        IERC20(newWantAddress).safeTransfer(vaultChefAddress, _bonusAmt);
        uint256 bonusAfter = bonusWantLockedTotal();

        return bonusBefore.sub(bonusAfter);
    }


    function earn() external nonReentrant whenNotPaused onlyGov {
        // Harvest farm tokens (dino makes you withdraw the whole LP *shrugs all around boys*)
        uint256 totalWithdraw;
        uint256 rewardDebt;
        (totalWithdraw, rewardDebt) = IMasterchef(masterchefAddress).userInfo(pid, address(this));
        
        
        IMasterchef(masterchefAddress).withdraw(pid, totalWithdraw);

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));


        //broke the fee functions here, only left the one that swaps matic to pay for gas.
        if (earnedAmt > 0) {
            earnedAmt = distributeFees(earnedAmt);
    

            // Swap earned to bonusWant
            _safeSwap(
                earnedAddress,
                newWantAddress,
                earnedAmt,
                address(this)
            );


    
    
            lastEarnBlock = block.number;
    
            _farm();
        }
    }

    // To pay for earn function
    function distributeFees(uint256 _earnedAmt) internal returns (uint256) {
        if (controllerFee > 0) {
            uint256 fee = _earnedAmt.mul(controllerFee).div(feeMax); // this is 50 basis points by default, 0.5%

            //need to change this to and make a _safeSwapMatic()
            _safeSwapWmatic(
                fee,
                earnedToWmaticPath,
                govAddress 
            );
            
            _earnedAmt = _earnedAmt.sub(fee);
        }

        return _earnedAmt;
    }


    // Emergency!!
    function pause() external onlyGov {
        _pause();
    }

    // False alarm
    function unpause() external onlyGov {
        _unpause();
        _resetAllowances();
    }
    
    
    function vaultSharesTotal() public view returns (uint256) {
        (uint256 amount,) = IMasterchef(masterchefAddress).userInfo(pid, address(this));
        return amount;
    }
    
    function wantLockedTotal() public view returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this))
            .add(vaultSharesTotal());
    }

    function bonusWantLockedTotal() public view returns (uint256) {
        return IERC20(newWantAddress).balanceOf(address(this));
    }

    function bonusWantAddress() public view returns (address) {
        return newWantAddress;
    }

    function _resetAllowances() internal {
        IERC20(wantAddress).safeApprove(masterchefAddress, uint256(0));
        IERC20(wantAddress).safeIncreaseAllowance(
            masterchefAddress,
            uint256(-1)
        );

        IERC20(earnedAddress).safeApprove(uniRouterAddress, uint256(0));
        IERC20(earnedAddress).safeIncreaseAllowance(
            uniRouterAddress,
            uint256(-1)
        );
    }

    function resetAllowances() external onlyGov {
        _resetAllowances();
    }

    function panic() external onlyGov {
        _pause();
        IMasterchef(masterchefAddress).emergencyWithdraw(pid);
    }

    function unpanic() external onlyGov {
        _unpause();
        _farm();
    }
    
    function setSettings(
        uint256 _controllerFee,
        uint256 _slippageFactor,
        address _uniRouterAddress
    ) external onlyGov {
        require(_controllerFee <= feeMaxTotal, "Max fee of 10%");
        require(_slippageFactor <= slippageFactorUL, "_slippageFactor too high");

        controllerFee = _controllerFee;
        slippageFactor = _slippageFactor;
        uniRouterAddress = _uniRouterAddress;

        emit SetSettings(
            _controllerFee,
            _slippageFactor,
            _uniRouterAddress
        );
    }

    function setGov(address _govAddress) external onlyGov {
        govAddress = _govAddress;
    }
    
    function _findPath(address _tokenIn, address _tokenOut) public returns (address[] memory _path) {
        address[] memory path;
        path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH;
        path[2] = _tokenOut;
        return path;
    }

    function _safeSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _to
    ) internal {

        address[] memory _path = _findPath(_tokenIn, _tokenOut);



        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IUniRouter02(uniRouterAddress).swapExactTokensForTokens(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            block.timestamp.add(600)
        );
    }


    
    function _safeSwapWmatic(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(2)]; //change back to .sub(1)

        IUniRouter02(uniRouterAddress).swapExactTokensForETH(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            now.add(600)
        );
    }
    //needed to accept ether
    event Received(address sender, uint amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}