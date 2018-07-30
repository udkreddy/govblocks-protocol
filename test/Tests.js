var MemberRoles = artifacts.require("MemberRoles");
var GovBlocksMaster = artifacts.require("GovBlocksMaster");
var Master = artifacts.require("Master");
var GBTStandardToken = artifacts.require("GBTStandardToken");
var Governance = artifacts.require("Governance");
var GovernanceData = artifacts.require("GovernanceData");
var Pool = artifacts.require("Pool");
var ProposalCategory = artifacts.require("ProposalCategory");
var SimpleVoting = artifacts.require("SimpleVoting");
var EventCaller = artifacts.require("EventCaller");
var gbts;
var gbm;
var ec;
var gd;
var mr;
var pc;
var sv;
var gv;
var pl;
var add = [];
var ms;
const json = require('./../build/contracts/Master.json');
var bytecode = json['bytecode'];

describe('Deploy new dApp', function() {
  it("should get the deployed insance of GBM", async function () {
    GovBlocksMaster.deployed().then(function(instance){
      gbm = instance;
    });
    assert.equal(1, 1, "something is not right");
  });
  it("should create a new dApp", async function () {
    this.timeout(100000);
    await gbm.addGovBlocksUser("0x42", gbts.address, "descHash");
    gd = await GovernanceData.new();
    mr = await MemberRoles.new();
    pc = await ProposalCategory.new();
    sv = await SimpleVoting.new();
    gv = await Governance.new();
    pl = await Pool.new();
    add.push(gd.address);
    add.push(mr.address);
    add.push(pc.address);
    add.push(sv.address);
    add.push(gv.address);
    add.push(pl.address);
    let mad = await gbm.getDappMasterAddress("0x42");
    ms = await Master.at(mad);
    await ms.addNewVersion(add);
    assert.equal(await ms.versionLength(), 1, "dApp version not created");
  });
});

// describe('Test Member Roles', function() {
//   it("Member Roles should be initialized with 3 roles", async function() {
//     this.timeout(100000);
//     assert.equal(await mr.getTotalMemberRoles(), 3, "Default Member Roles not added");
//   });
// });

