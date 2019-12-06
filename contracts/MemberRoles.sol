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
import "./interfaces/IMemberRoles.sol";
import "./imports/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./imports/lockable-token/LockableToken.sol";
import "./imports/govern/Governed.sol";


contract MemberRoles is IMemberRoles, Governed {

    enum Role {
        UnAssigned,
        AdvisoryBoard,
        TokenHolder
    }

    LockableToken public dAppToken;

    struct MemberRoleDetails {
        uint memberCounter;
        mapping(address => bool) memberActive;
        address[] memberAddress;
        address authorized;
    }

    MemberRoleDetails[] internal memberRoleData;
    bool internal constructorCheck;

    modifier checkRoleAuthority(uint _memberRoleId) {
        if (memberRoleData[_memberRoleId].authorized != address(0))
            require(msg.sender == memberRoleData[_memberRoleId].authorized);
        else
            require(isAuthorizedToGovern(msg.sender), "Not Authorized");
        _;
    }

    /// @dev To Initiate default settings whenever the contract is regenerated!
    function updateDependencyAddresses() public pure { //solhint-disable-line
    }

    /// @dev just to adhere to GovBlockss' Upgradeable interface
    function changeMasterAddress(address _masterAddress) public { //solhint-disable-line
        if(masterAddress == address(0))
            masterAddress = _masterAddress;
        else{
            require(msg.sender == masterAddress);
            masterAddress = _masterAddress;
        }
    }

    function memberRolesInitiate(address _dAppToken, address _firstAB) public {
        require(!constructorCheck);
        dAppToken = LockableToken(_dAppToken);
        addInitialMemberRoles(_firstAB);
        constructorCheck = true;
    }

    function addInitialMemberRoles(address _firstAB) internal {
        _addRole("Unassigned", "Unassigned", address(0));
        _addRole(
            "Advisory Board",
            "Selected few members that are deeply entrusted by the dApp. An ideal advisory board should be a mix of skills of domain, governance, research, technology, consulting etc to improve the performance of the dApp.", //solhint-disable-line
            address(0)
        );
        _addRole(
            "Token Holder",
            "Represents all users who hold dApp tokens. This is the most general category and anyone holding token balance is a part of this category by default.", //solhint-disable-line
            address(0)
        );
        _updateRole(_firstAB, 1, true);
    }

    /// @dev Adds new member role
    /// @param _roleName New role name
    /// @param _roleDescription New description hash
    /// @param _authorized Authorized member against every role id
    function addRole( //solhint-disable-line
        bytes32 _roleName,
        string _roleDescription,
        address _authorized
    )
    public
    onlyAuthorizedToGovern {
        _addRole(_roleName, _roleDescription, _authorized);
    }

    /// @dev Assign or Delete a member from specific role.
    /// @param _memberAddress Address of Member
    /// @param _roleId RoleId to update
    /// @param _active active is set to be True if we want to assign this role to member, False otherwise!
    function updateRole( //solhint-disable-line
        address _memberAddress,
        uint _roleId,
        bool _active
    )
    public
    checkRoleAuthority(_roleId) {
        _updateRole(_memberAddress, _roleId, _active);
    }

    /// @dev Return number of member roles
    function totalRoles() public view returns(uint256) { //solhint-disable-line
        return memberRoleData.length;
    }

    /// @dev Change Member Address who holds the authority to Add/Delete any member from specific role.
    /// @param _roleId roleId to update its Authorized Address
    /// @param _newAuthorized New authorized address against role id
    function changeAuthorized(uint _roleId, address _newAuthorized) external checkRoleAuthority(_roleId) { //solhint-disable-line
        memberRoleData[_roleId].authorized = _newAuthorized;
    }

    /// @dev Gets the member addresses assigned by a specific role
    /// @param _memberRoleId Member role id
    /// @return roleId Role id
    /// @return allMemberAddress Member addresses of specified role id
    function members(uint _memberRoleId) public view returns(uint, address[] memberArray) { //solhint-disable-line
        uint length = memberRoleData[_memberRoleId].memberAddress.length;
        uint i;
        uint j;
        memberArray = new address[](memberRoleData[_memberRoleId].memberCounter);
        for (i = 0; i < length; i++) {
            address member = memberRoleData[_memberRoleId].memberAddress[i];
            if (memberRoleData[_memberRoleId].memberActive[member] && !checkMemberInArray(member, memberArray)) { //solhint-disable-line
                memberArray[j] = member;
                j++;
            }
        }
        
        return (_memberRoleId, memberArray);
    }

    /// @dev Gets all members' length
    /// @param _memberRoleId Member role id
    /// @return memberRoleData[_memberRoleId].memberCounter Member length
    function numberOfMembers(uint _memberRoleId) public view returns(uint) { //solhint-disable-line
        return memberRoleData[_memberRoleId].memberCounter;
    }

    /// @dev Return member address who holds the right to add/remove any member from specific role.
    function authorized(uint _memberRoleId) public view returns(address) { //solhint-disable-line
        return memberRoleData[_memberRoleId].authorized;
    }

    /// @dev Get All role ids array that has been assigned to a member so far.
    function roles(address _memberAddress) public view returns(uint[] assignedRoles) { //solhint-disable-line
        uint length = memberRoleData.length;
        uint j = 0;
        uint i;
        uint[] memory tempAllMemberAddress = new uint[](length);
        for (i = 1; i < length; i++) {
            if (memberRoleData[i].memberActive[_memberAddress]) {
                tempAllMemberAddress[j] = i;
                j++;
            }
        }
        if (dAppToken.totalBalanceOf(_memberAddress) > 0) {
            tempAllMemberAddress[j] = uint(Role.TokenHolder);
        }

        assignedRoles = new uint[](j);
        for (i = 0; i < j; i++) {
            assignedRoles[i] = tempAllMemberAddress[i];
        }
        return assignedRoles;
    }

    /// @dev Returns true if the given role id is assigned to a member.
    /// @param _memberAddress Address of member
    /// @param _roleId Checks member's authenticity with the roleId.
    /// i.e. Returns true if this roleId is assigned to member
    function checkRole(address _memberAddress, uint _roleId) public view returns(bool) { //solhint-disable-line
        if (_roleId == uint(Role.UnAssigned))
            return true;
        else if (_roleId == uint(Role.TokenHolder)) {
            if (dAppToken.totalBalanceOf(_memberAddress) > 0)
                return true;
            else
                return false;
        } else
            if (memberRoleData[_roleId].memberActive[_memberAddress]) //solhint-disable-line
                return true;
            else
                return false;
    }

    /// @dev Return total number of members assigned against each role id.
    /// @return totalMembers Total members in particular role id
    function getMemberLengthForAllRoles() public view returns(uint[] totalMembers) { //solhint-disable-line
        totalMembers = new uint[](memberRoleData.length);
        for (uint i = 0; i < memberRoleData.length; i++) {
            totalMembers[i] = numberOfMembers(i);
        }
    }

    function _updateRole(address _memberAddress,
        uint _roleId,
        bool _active) internal {
        require(_roleId != uint(Role.TokenHolder), "Membership to Token holder is detected automatically");
        if (_active) {
            require(!memberRoleData[_roleId].memberActive[_memberAddress]);
            memberRoleData[_roleId].memberCounter = SafeMath.add(memberRoleData[_roleId].memberCounter, 1);
            memberRoleData[_roleId].memberActive[_memberAddress] = true;
            memberRoleData[_roleId].memberAddress.push(_memberAddress);
        } else {
            require(memberRoleData[_roleId].memberActive[_memberAddress]);
            memberRoleData[_roleId].memberCounter = SafeMath.sub(memberRoleData[_roleId].memberCounter, 1);
            delete memberRoleData[_roleId].memberActive[_memberAddress];
        }
    }

    /// @dev Adds new member role
    /// @param _roleName New role name
    /// @param _roleDescription New description hash
    /// @param _authorized Authorized member against every role id
    function _addRole(
        bytes32 _roleName,
        string _roleDescription,
        address _authorized
    ) internal {
        emit MemberRole(memberRoleData.length, _roleName, _roleDescription);
        memberRoleData.push(MemberRoleDetails(0, new address[](0), _authorized));
    }

    function checkMemberInArray(address _memberAddress, address[] memberArray) internal view returns(bool memberExists){
        uint i;
        for(i = 0; i<memberArray.length; i++){
            if(memberArray[i] == _memberAddress){
                memberExists = true;
                break;
            }
        }
    }

}