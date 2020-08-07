const Migrations = artifacts.require("Migrations");
const HitchensOrderStatisticsTreeLib = artifacts.require("HitchensOrderStatisticsTreeLib")
const HitchensOrderStatisticsTree = artifacts.require("HitchensOrderStatisticsTree")
const Owned = artifacts.require("Owned")

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Owned);
  deployer.deploy(HitchensOrderStatisticsTreeLib);
  deployer.link(HitchensOrderStatisticsTreeLib, HitchensOrderStatisticsTree);
  deployer.deploy(HitchensOrderStatisticsTree);
};
