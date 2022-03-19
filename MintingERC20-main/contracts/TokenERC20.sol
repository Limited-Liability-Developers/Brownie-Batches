pragma solidity 0.8.0;

import "@oz/contracts/token/ERC20/ERC20.sol";
//constructor is minting based now

//minting based ERC20
contract MinterToken is ERC20 {
    uint256 _mintCounter;

    //mapping
    mapping(uint256 => address) public mintIdToCaller;

    constructor () ERC20("Minter Token", "MINT") {
        _mintCounter = 0;
    }

    function mintRack() public {
        _mint(msg.sender, 1000 ether);
        uint mintId = _mintCounter;
        mintIdToCaller[mintId] = msg.sender;
        _mintCounter = _mintCounter + 1;
    }

    function countMints() public view returns(uint256) {
        return _mintCounter;
    }

    function findMinter(uint256 mintId) public view returns (address) {
        address minter = mintIdToCaller[mintId];
        return minter;
    }

    function lastMinter() public view returns (address) {
        uint256 last = _mintCounter - 1;
        address lastMinter = findMinter(last);
        return lastMinter;
    }

}