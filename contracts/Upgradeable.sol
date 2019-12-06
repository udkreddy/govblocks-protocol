/* Copyright (C) 2017 GovBlocks.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.4.24;

import "./Master.sol";


contract Upgradeable {

    Master public master;

    modifier onlyInternal {
        require(master.isInternal(msg.sender));
        _;
    }

    function updateDependencyAddresses() public; //To be implemented by every contract depending on its needs

    function changeMasterAddress(address _masterAddress) public {
        if (address(master) == address(0))
            master = Master(_masterAddress);
        else {
            require(msg.sender == address(master));
            master = Master(_masterAddress);
        }
    }
}