pragma solidity ^0.4.24;

contract GovernChecker {
    function authorized(bytes32 _dAppName) public view returns(address);
}

contract Governed {

    GovernChecker internal governChecker;

    bytes32 internal dAppName;

    modifier onlyAuthorizedToGovern() {
        require(governChecker.authorized(dAppName) == msg.sender);
        _;
    }

    function Governed (bytes32 _dAppName) {
        setGovernChecker();
        dAppName = _dAppName;
    } 

    function setGovernChecker() public {
        if (getCodeSize(0x56f8fec317d95c9eb755268abc2afb99afbdcb47) > 0)        //kovan testnet
            governChecker = GovernChecker(0x56f8fec317d95c9eb755268abc2afb99afbdcb47);
        else if (getCodeSize(0x56f8fec317d95c9eb755268abc2afb99afbdcb47) > 0)   //RSK testnet
            governChecker = GovernChecker(0x56f8fec317d95c9eb755268abc2afb99afbdcb47);
    }

    function getCodeSize(address _addr) internal view returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function getGovernCheckerAddress() public view returns(address) {
        return address(governChecker);
    }
}