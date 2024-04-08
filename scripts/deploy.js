const DvAsset = artifacts.require("DvAsset");
const DvAssetFactory = artifacts.require("DvAssetFactory");

module.exports = function(deployer) {
    if (deployer.network === 'development') {
        deployer.deploy(DvAssetFactory)
            .then(() => DvAssetFactory.deployed())
            .then(async _instance => {
                await _instance.setFee(0, 0);
            });
    } else {
        deployer.deploy(DvAssetFactory)
            .then(() => DvAssetFactory.deployed())
            .then(async _instance => {
                await _instance.setFee(0, 0);
            });
    }
};
