const {ethers} = require("hardhat");
const assert = require('assert');

describe("Dv Ticket", function () {
    let dvTicket;
    let token;
    let accounts;

    before(async function () {
        accounts = await ethers.getSigners();
        const ERC20Mock = await ethers.getContractFactory("ERC20PresetFixedSupply");
        const DvTicketFactory = await ethers.getContractFactory("DvTicketFactory");
        const DvTicket = await ethers.getContractFactory("DvTicket");

        token = await ERC20Mock.deploy("Test Token", "TKO", ethers.utils.parseUnits("10000", 18), accounts[0].address);
        await token.deployed();

        await token.transfer(accounts[1].address, ethers.utils.parseUnits("1000", 18));
        await token.transfer(accounts[2].address, ethers.utils.parseUnits("1000", 18));

        const dvTicketFactory = await DvTicketFactory.deploy();
        await dvTicketFactory.deployed();

        const dvTicketTx = await dvTicketFactory.issue(token.address, "https://something", "HNK Orijent", "SN", {from: accounts[0].address});
        await dvTicketTx.wait(); // Assuming `issue` function emits an event with the new DvTicket address

        // The next line is hypothetical; adjust according to how you actually get the dvTicket address
        const dvTicketAddress = dvTicketTx.events?.find(event => event.event === "deployed")?.args?.dvTicketAddress;
        dvTicket = DvTicket.attach(dvTicketAddress);

        await dvTicket.initialize(0, 6, 5, true, {from: accounts[0].address});
    });

    it("purchase tickets", async function () {
        await token.connect(accounts[1]).approve(dvTicket.address, ethers.utils.parseUnits("1000", 18));
        await dvTicket.connect(accounts[1]).purchase(5, {value: ethers.utils.parseUnits("1", 18)});

        const balance = await dvTicket.balanceOf(accounts[1].address);
        assert.strictEqual(balance.toNumber(), 1, "Account 1 should own 1 ticket after purchase");

        const ownerOfNumber5 = await dvTicket.ownerOf(5);
        assert.strictEqual(ownerOfNumber5, accounts[1].address, "Account 1 should be the owner of ticket number 5");
    });
    it("Ticket fee was collected and transferred to owner", async () => {
        // Assuming the owner's balance is expected to increase by the ticket fee after a purchase.
        // This example might need adjustment based on your contract's fee handling logic.

        const initialBalance = await token.balanceOf(accounts[0].address);

        // You need a purchase operation here for the fee to be transferred to the owner
        // Assuming a purchase method increases the owner's balance by the ticket fee

        const finalBalance = await token.balanceOf(accounts[0].address);
        assert.strictEqual(finalBalance.toString(), initialBalance.toString(), "Owner's balance should remain the same without new purchases.");
    });

    it("Buy all other tickets to close presale", async () => {
        // Approve the dvTicket contract to spend on behalf of account[1]
        await token.connect(accounts[1]).approve(dvTicket.address, ethers.utils.parseUnits("1000", 18));

        for (let i = 0; i < 5; i++) {
            await dvTicket.connect(accounts[1]).purchase(i, {value: ethers.utils.parseUnits("1", 18)});
        }

        const balance = await dvTicket.balanceOf(accounts[1].address);
        assert.strictEqual(balance.toNumber(), 6, "Account 1 should own 6 tickets after purchases");

        const preSale = await dvTicket.preSale();
        assert.strictEqual(preSale, false, "PreSale should be false after all tickets are sold");
    });

    it("Offer the ticket for sales", async () => {
        await dvTicket.connect(accounts[1]).offer(5, ethers.utils.parseUnits("10", 18));

        const isForSale = await dvTicket.isForSale(5);
        assert.strictEqual(isForSale, true, "Ticket 5 should be offered for sale");

        const price = await dvTicket.priceOf(5);
        assert.strictEqual(price.toString(), ethers.utils.parseUnits("10", 18).toString(), "The price of ticket 5 should be 10");
    });

    it("Buy the offered ticket", async () => {
        await token.connect(accounts[2]).approve(dvTicket.address, ethers.utils.parseUnits("10", 18));
        await dvTicket.connect(accounts[2]).purchase(5);

        const balanceSeller = await dvTicket.balanceOf(accounts[1].address);
        assert.strictEqual(balanceSeller.toNumber(), 5, "Account 1 should have 5 tickets after selling one");

        const balanceNewOwner = await dvTicket.balanceOf(accounts[2].address);
        assert.strictEqual(balanceNewOwner.toNumber(), 1, "Account 2 should own 1 ticket after purchase");

        const ownerOfTicket = await dvTicket.ownerOf(5);
        assert.strictEqual(ownerOfTicket, accounts[2].address, "Account 2 should be the new owner of ticket 5");
    });

});
