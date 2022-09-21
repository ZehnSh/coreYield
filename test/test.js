const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");

const { expect } = require("chai");
const {ethers}  = require("hardhat");

describe("YieldSourceTest", function () {
  let owner, addr1,addr2;
  let assetToken;
  let yieldSourceA;
  let yieldSourcePrizePool;
  let ticketContract;
  beforeEach("",async function(){

    [owner,addr1,addr2] = await ethers.getSigners();

    const AssetToken = await ethers.getContractFactory("Tokens");
    const assettoken = await AssetToken.deploy(1000);
    assetToken = await assettoken.deployed();

    const YieldSource = await ethers.getContractFactory("yieldSourceA");
    const yieldsource = await YieldSource.deploy(assetToken.address);
    yieldSourceA = await yieldsource.deployed();

    console.log(yieldSourceA.address)

    const YieldSourcePrizePool = await ethers.getContractFactory("YieldSourcePrizePool");
    const yieldsourceprizepool = await YieldSourcePrizePool.deploy(owner.address,yieldSourceA.address);
    yieldSourcePrizePool = await yieldsourceprizepool.deployed();

    console.log(yieldSourcePrizePool.address)

    const Tickets = await ethers.getContractFactory("Tickets");
    const ticket = await Tickets.deploy("TicketTokens","TTT",1,yieldSourcePrizePool.address);
    ticketContract = await ticket.deployed();

    console.log(ticketContract.address);

    await yieldSourcePrizePool.setTicket(ticketContract.address);


    await assetToken.connect(addr1).mint(addr1.address,1000);
    await assetToken.connect(addr2).mint(addr2.address,1000);
  
    await assetToken.approve(yieldSourcePrizePool.address,1000);
    await assetToken.connect(addr1).approve(yieldSourcePrizePool.address,1000);
    await assetToken.connect(addr2).approve(yieldSourcePrizePool.address,1000);
  })

  it("should return asset token name correctly", async ()=>{
    const name = await assetToken.name();
    expect(name).to.equal("Gold");
  });

  it("should return token address correctly", async ()=>{
    const ticketAddress =  await yieldSourcePrizePool.getToken()
 
    expect(ticketAddress).to.equal(assetToken.address);
   });

  it("should return ticket address correctly", async ()=>{
   const ticketAddress =  await yieldSourcePrizePool.getTicket()

   expect(ticketAddress).to.equal(ticketContract.address);
  });

  it("should return ticket controller and in yield source should return the ticket address correctly", async ()=>{
    const isControlled =  await yieldSourcePrizePool.isControlled(ticketContract.address);
    const controller = await ticketContract.controller();
 
    expect(isControlled).to.equal(true);
    expect(controller).to.equal(yieldSourcePrizePool.address);


   });

  it("should return th allowance we set in beforeEach block", async ()=>{
    const allowance =  await assetToken.allowance(owner.address,yieldSourcePrizePool.address);
 
    expect(allowance).to.equal(1000);
   });


   it("ticket should be minted in msg.sender account and userShare should be updated", async ()=>{
    await yieldSourcePrizePool.depositTo(owner.address,50);
    const ticketbalance = await ticketContract.balanceOf(owner.address);

    console.log(ticketbalance);
    expect(ticketbalance).to.equal(50);

    const shares = await yieldSourcePrizePool.User(owner.address);
    expect(ticketbalance).to.equal(shares.userShare);
   });


   it("user shares should be equal to the amount withdrawn and userShare should be updated",async ()=>{

    await yieldSourcePrizePool.depositTo(owner.address,50);
    await yieldSourcePrizePool.depositTo(owner.address,50);
    const ticketbalance = await ticketContract.balanceOf(owner.address);

    expect(ticketbalance).to.equal(100);
    const withdrawamount = await yieldSourcePrizePool.withdrawFrom(owner.address,50);
    // console.log("this",withdrawamount);
    // expect(withdrawamount).to.equal(50);

    const usershares = await yieldSourcePrizePool.User(owner.address);
    expect(usershares.userShare).to.equals(50)
    

   });

   it("yield should be minted in the yield source",async ()=>{
    await yieldSourcePrizePool.depositTo(owner.address,50);
    await yieldSourcePrizePool.connect(addr1).depositTo(addr1.address,50);

    expect(await assetToken.balanceOf(yieldSourceA.address)).to.equal(100);

   await yieldSourceA.yield(100);

   expect(await assetToken.balanceOf(yieldSourceA.address)).to.equal(200);

   });


   it("the amount should be distributed by the ratio of yield",async ()=>{
    await yieldSourcePrizePool.depositTo(owner.address,50);
    await yieldSourcePrizePool.connect(addr1).depositTo(addr1.address,50);
    await yieldSourcePrizePool.connect(addr2).depositTo(addr2.address,50);

    const tokenBalance = await assetToken.balanceOf(yieldSourceA.address);
    expect(tokenBalance).to.equal(150);
    await yieldSourceA.yield(150);
    await yieldSourcePrizePool.withdrawFrom(owner.address,50);
    await yieldSourcePrizePool.connect(addr1).withdrawFrom(addr1.address,50);
    await yieldSourcePrizePool.connect(addr2).withdrawFrom(addr2.address,50);
    expect(await assetToken.balanceOf(owner.address)).to.equal(1050);
    expect(await assetToken.balanceOf(addr1.address)).to.equal(1050);
    expect(await assetToken.balanceOf(addr2.address)).to.equal(1050);
 

   });


  
});
