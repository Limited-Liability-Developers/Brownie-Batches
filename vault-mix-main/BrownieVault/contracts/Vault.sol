pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Vault {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    
    
    struct Vault {
        IERC20 asset; // Address of the want token.
        uint256 amount;
    }
    
    struct UserInfo {
        uint256 shares; // How many LP tokens the user has provided.
    }
    
    //create mapping of number to Vault struct; indicating total vaults as well as setting up the ability to index vaults by number later
   
    Vault[] public vaults; // Info of each pool.
    
    mapping(uint256 => mapping(address => UserInfo)) public userinfo; //info of each user
    
    mapping(address => bool) private assets; //to check if we already have a vault for an asset, prevent duplication of vaults
    
    
    
    
    function getVaultLength() external view returns (uint256) {
        return vaults.length;
    }
    
    event VaultLog(string msg, uint256 val);
    event DepositLog(string msg, uint256 val);
    event VaultLoggier(string msg, address adrs);
    event WithdrawLog(string msg, uint256 val);
    
    function createVault(address _asset) public returns (uint256) {
        require(!assets[_asset], "Vault Already Exists for this Asset");
        
        vaults.push(
            Vault({
                asset: IERC20(_asset),
                amount: 0
            })
            );
            
        assets[_asset] = true; //since we just created a vault with asset in line 35, set to true, so in future line 33 will reject new vault for asset
        
        emit VaultLog("Vauld ID", vaults.length.sub(1));
        emit VaultLoggier("Vault Created for: ", _asset);
        return vaults.length.sub(1);
        
        
    }
    
    function deposit(uint256 _amount, uint256 _pid) public {
        Vault storage vault = vaults[_pid];
        UserInfo storage user = userinfo[_pid][msg.sender]; //access mapping to get user info of current caller
        
        require(_amount > 0);
        vault.asset.safeTransferFrom(msg.sender, address(this), _amount); //this line will require a user to approve this contract to spend
        
        vault.amount = vault.amount.add(_amount);
        user.shares = user.shares.add(_amount);
        
        emit DepositLog("User's shares of vault", user.shares);
        
        
    }
    

    
    function withdraw(uint256 _amount, uint256 _pid) public returns (uint256 vaultBalance){
        Vault storage vault = vaults[_pid];
        UserInfo storage user = userinfo[_pid][msg.sender];
        
        uint256 vaultBalanceStart = IERC20(vault.asset).balanceOf(address(this));
        
        if (_amount > user.shares) {
            _amount = user.shares;
            vault.asset.safeTransfer(msg.sender, _amount);
            user.shares = 0;
        } else if (_amount < user.shares) {
            vault.asset.safeTransfer(msg.sender, _amount);
            user.shares = user.shares.sub(_amount);
        }
        
        uint256 vaultBalanceEnd = IERC20(vault.asset).balanceOf(address(this));
        
        return vaultBalanceEnd;
        

        
    
        
    }
    
    
    
    
    
}