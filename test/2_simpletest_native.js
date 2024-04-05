const DvTicketFactory = artifacts.require("DvTicketFactory");
const DvTicket = artifacts.require("DvTicket");
const ERC20Mock = artifacts.require("ERC20PresetFixedSupply"); // This is a mock ERC20 token for testing

contract("DvTicket Native", accounts => {
    let dvTicket;
    let token;

    before(async () => {
        const dvTicketFactory = await DvTicketFactory.deployed();

        dvTicket = await dvTicketFactory.issue("0x0000000000000000000000000000000000000000", "https://something", "HNK Orijent", "SN", { from: accounts[0] });
        dvTicket = await DvTicket.at(dvTicket.logs[0].args[1]);
        await dvTicket.initialize(0, 6, 5, true, { from: accounts[0] });
    });

    it("purchase tickets", async () => {
        let price = await dvTicket.price.call()
        price = price.toNumber();

        await dvTicket.purchase(5, {from: accounts[1], value : 5});

        const ownerOfNumber5 = await dvTicket.ownerOf(5);
        assert.equal(ownerOfNumber5, accounts[1]);
    });

    it("Ticket fee was collected and transferred to owner", async () => {
        // check balance on contract
        const balance = parseInt(await web3.eth.getBalance(accounts[0]));

        // check balance on owner
        const balanceAfterWithdraw = parseInt(await web3.eth.getBalance(accounts[0]));
        //assert.equal(balanceAfterWithdraw, balance + 5);
    });

    it("Buy all other tickets to close presale", async () => {
        await dvTicket.purchase(0, {from: accounts[1], value : 5});
        await dvTicket.purchase(1, {from: accounts[1], value : 5});
        await dvTicket.purchase(2, {from: accounts[1], value : 5});
        await dvTicket.purchase(3, {from: accounts[1], value : 5});
        await dvTicket.purchase(4, {from: accounts[1], value : 5});

        const balance = await dvTicket.balanceOf(accounts[1]);
        assert.equal(balance.toNumber(), 6);

        const preSale = await dvTicket.preSale.call();
        assert.equal(preSale, false);
    })

    it("Offer the ticket for sales", async () => {
        //const isForSale = await dvTicket.isForSale(5);
        //const isOwner = await dvTicket.ownerOf(5);
        await dvTicket.offer(5, 10, {from: accounts[1] });

        const ticket = await dvTicket.isForSale(5);
        assert.equal(ticket, true);

        const price = await dvTicket.priceOf(5);
        assert.equal(price.toNumber(), 10);
    });

    it("Buy the offered ticket", async () => {
        await dvTicket.purchase(5, {from: accounts[2], value: 10 });

        const balance = await dvTicket.balanceOf(accounts[1]);
        assert.equal(balance.toNumber(), 5);

        const balanceNewOnwer = await dvTicket.balanceOf(accounts[2]);
        assert.equal(balanceNewOnwer.toNumber(), 1);

        const ownerOfNumber5 = await dvTicket.ownerOf(5);
        assert.equal(ownerOfNumber5, accounts[2]);
    });

});
