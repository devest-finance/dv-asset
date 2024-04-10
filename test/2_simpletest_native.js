const { ethers } = require("hardhat");
const assert = require('assert');

describe("DvAsset Native", function () {
    let dvAssetFactory, dvAsset, accounts, dvAssetAddress;
    const priceValue = ethers.utils.parseUnits("5", "wei");

    const fee = ethers.utils.parseUnits("0.01", "ether");
    const issueFee = ethers.utils.parseUnits("1", "ether");

    before(async function () {
        accounts = await ethers.getSigners();
        const DvAssetFactory = await ethers.getContractFactory("DvAssetFactory");
        dvAssetFactory = await DvAssetFactory.deploy();
        await dvAssetFactory.deployed();
        // await dvAssetFactory.setFee(fee, issueFee);
        // await dvAssetFactory.setRecipient(accounts[0].address);

        // Assuming issue emits an event with the new dvAsset address as the first argument
        const issueTx = await dvAssetFactory.issue("0x0000000000000000000000000000000000000000", "https://something", "DvAsset", "DVA", { value: priceValue });
        const issueTxReceipt = await issueTx.wait();
        dvAssetAddress = issueTxReceipt.events?.filter((x) => x.event === "deployed")[0].args[1];

        dvAsset = await ethers.getContractAt("DvAsset", dvAssetAddress);
        await dvAsset.initialize(0, 6, 5, true, false);
    });

    it("purchase tickets", async function () {
        console.log("accounts 1 balance");
        console.log(await dvAsset.balanceOf(accounts[1].address));
        const tx = await dvAsset.connect(accounts[1]).purchase(5, { value: priceValue });
        await tx.wait();

        const ownerOfNumber5 = await dvAsset.ownerOf(5);
        assert.strictEqual(ownerOfNumber5, accounts[1].address, "Account 1 should own ticket number 5");
    });

    it("Ticket fee was collected and transferred to owner", async function () {
        const ownerAddress = accounts[0].address;
        const initialBalance = await ethers.provider.getBalance(ownerAddress);
        // simulate purchase to change the balance here...
        const finalBalance = await ethers.provider.getBalance(ownerAddress);
        const priceValueBigNumber = ethers.utils.parseUnits("5", "wei");
        const expectedFinalBalance = initialBalance.add(priceValueBigNumber);
        assert.strictEqual(finalBalance.toString(), expectedFinalBalance.toString(), "Final balance does not match expected value.");
    });

    it("Buy all other tickets to close presale", async function () {
        const signer1 = accounts[1];
        const purchaseValue = ethers.utils.parseUnits("5", "wei");

        for (let i = 0; i < 5; i++) {
            await dvAsset.connect(signer1).purchase(i, { value: purchaseValue });
        }

        const balance = await dvAsset.balanceOf(signer1.address);
        assert.strictEqual(balance.toNumber(), 6, "Balance should be 6 after purchasing all tickets.");

        const preSale = await dvAsset.preSale();
        assert.strictEqual(preSale, false, "PreSale should be false after all tickets are sold.");
    });

    it("Offer the ticket for sales", async function () {
        const signer1 = accounts[1];
        await dvAsset.connect(signer1).offer(5, ethers.utils.parseUnits("10", "wei"));
        const isForSale = await dvAsset.isForSale(5);
        assert.strictEqual(isForSale, true, "Ticket 5 should be marked as for sale.");

        const price = await dvAsset.priceOf(5);
        assert.strictEqual(price.toString(), ethers.utils.parseUnits("10", "wei").toString(), "The price of ticket 5 should be set to 10 wei.");
    });

    it("Buy the offered ticket", async function () {
        const signer2 = accounts[2];
        const ticketId = 5;
        const salePrice = ethers.utils.parseUnits("10", "wei");

        await dvAsset.connect(signer2).purchase(ticketId, { value: salePrice });

        const balanceSeller = await dvAsset.balanceOf(accounts[1].address);
        assert.strictEqual(balanceSeller.toNumber(), 5, "Seller's balance should be 5 after the sale.");

        const balanceNewOwner = await dvAsset.balanceOf(signer2.address);
        assert.strictEqual(balanceNewOwner.toNumber(), 1, "New owner's balance should be 1 after the purchase.");

        const ownerOfTicket = await dvAsset.ownerOf(ticketId);
        assert.strictEqual(ownerOfTicket, signer2.address, "The new owner of ticket 5 should be account 2.");
    });
});
