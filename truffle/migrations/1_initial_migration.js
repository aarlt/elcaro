const Migrations = artifacts.require("Migrations");
const Owned = artifacts.require("Owned")
const EnumerableSet = artifacts.require("EnumerableSet")
const Elcaro = artifacts.require("Elcaro")

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Owned);
  deployer.deploy(EnumerableSet);
  deployer.link(EnumerableSet, Elcaro);
  deployer.deploy(Elcaro)
};
