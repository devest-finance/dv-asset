const DvTicket = artifacts.require("DvTicket");
const DvTicketFactory = artifacts.require("DvTicketFactory");

module.exports = function(deployer) {
  if (deployer.network === 'development') {
      deployer.deploy(DvTicketFactory)
          .then(() => DvTicketFactory.deployed())
          .then(async _instance => {
                await _instance.setFee(0, 0);
          });
  } else {
      deployer.deploy(DvTicketFactory)
          .then(() => DvTicketFactory.deployed())
          .then(async _instance => {
              await _instance.setFee(0, 0);
          });
  }
};
