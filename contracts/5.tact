import "@stdlib/deploy";

/*
  TASK 5 - NFT random swap 
  The smart contract contains a bunch of different NFTs.
  A user brings his NFT (sends it to the smart contract), with 2.1 TON (2 for admin's profit, 0.1 for gas) in attachment (as fee for swap).
  The smart contract randomly chooses some NFT from the available NFTs (including the newly incoming one) and gives it to the user in exchange for the brought NFT (but occasionally just returns user's NFT in some cases).
  Admin can deposit NFTs without swap logic. Any NFT received from the admin is considered deposited. Admin can't swap.
  Admin can withdraw all NFTs at once, and also all TONs collected from users as fees.
  Implement getter that will return NFT addresses held by the smart contract.
  Implement getter that will return the amount of admin`s profit collected.

  In details, the smart contract (later: SC) should have this logic:
  Messages
  * AdminWithdrawalProfit 
   - SC should check that sender is the admin / otherwise throw "Insufficient privelegies"
   - SC should send all collected fees to admin except 0.1 TON (use AdminFetchProfit message as body)
     In other words: after each such operation, the contract's balance should be equal to 0.1 TON (which are reserved for storage) and the rest should be sent to the admin
  * AdminWithdrawalAllNFTs
   - SC should check that incoming tx TON value is enough for NFT withdrawal. Specifically, at least: (1 + totalNftsHeld * 0.08) TONs. Otherwise throw "Insufficent funds"
   - SC should check that sender is the admin, throw "Invalid sender" otherwise
   - If all checks pass, SC should send NFTs one by one to the admin 
   - SC should be able to withdraw all NFTs by a single message from admin
  * OwnershipAssigned 
   - if prevOwner is the owner's (admin) address, then add NFT to the collection
   - if value of TON attached is less then 2.1 TON then stop execution and return NFT back,
     but only in case that TON attached is enough to process refund without losing TONs on the SC's balance
   - randomly select NFT to send from all the NFTs that smart contract has
   - send the selected NFT to the sender with all remaining balance (except for admin profit = fees collected from this and other swaps)
     In other words: the contract's balance should increase by exactly 2 TON, some incoming TONs will be consumed for gas and the remainings of the incoming TONs should be refunded to the sender
  
  Getters
  * profit
   - returns how much collected fees is available to withdraw for the admin (all fees minus 0.1 TON)
  * nfts
   - returns dict of held NFTs with NFT indexes (sequential numbers from 0, 1, 2 ... and up to 'totalNftsHeld-1') as keys and NFT address as values 
     the order of NFTs in this dictionary doesn't matter
*/

message AdminWithdrawalProfit {
  queryId: Int as uint64;
}

message AdminWithdrawalAllNFTs {
  queryId: Int as uint64;
}

message AdminFetchProfit {
  queryId: Int as uint64;
}

message(0x05138d91) OwnershipAssigned {
  queryId: Int as uint64;
  prevOwner: Address;
  forwardPayload: Slice as remaining; 
}

message(0x5fcc3d14) Transfer { 
  queryId: Int as uint64;            
  newOwner: Address; 
  responseDestination: Address; 
  customPayload: Cell?; 
  forwardAmount: Int as coins; 
  forwardPayload: Slice as remaining; 
}

contract Task5 with Deployable {
  seed: Int as uint128;
  owner: Address;
  nfts: map<Int as uint16, Address>;
  countNfts: Int as uint16 = 0;
  
  init(seed: Int, owner: Address) {
    self.owner = owner;
    self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address
  }

  receive(msg: OwnershipAssigned) {
    if (msg.prevOwner == self.owner) {
      self.nfts.set(self.countNfts, sender());
      self.countNfts = self.countNfts + 1;
      return;
    }

    let b: Builder = beginCell();
    let body: Cell = b
        .storeUint(0x5fcc3d140000000000000000 + msg.queryId, 96)
        .storeAddress(msg.prevOwner)
        .storeAddress(msg.prevOwner)
        .storeUint(0, 5)
        .endCell();

    b = b.storeUint(0x18, 6);

    let value: Int = context().value;
    if (value < ton("2.1")) {

      let msgCell: Cell = b
        .storeAddress(sender())
        .storeUint(1, 111)
        .storeRef(body)
        .endCell();

      nativeSendMessage(msgCell, SendRemainingValue);
 
      return;
    }

    let key: Int = random(0, self.countNfts);
    let nft: Address = sender();
    if (key != self.countNfts) {
      nft = self.nfts.get(key)!!;
      self.nfts.set(key, sender());
    }

    let msgCell: Cell = b
        .storeAddress(nft)
        .storeCoins(value - ton("2.05"))
        .storeUint(1, 107)
        .storeRef(body)
        .endCell();

    nativeSendMessage(msgCell, SendIgnoreErrors);

  }

  receive(msg: AdminWithdrawalProfit) {
    require(sender() == self.owner, "Insufficient privelegies");
    nativeReserve(ton("0.1"), 0);
    
    let b: Builder = beginCell();
    let body: Cell = b
          // .storeUint(0xfda48b790000000000000000 + msg.queryId, 96)
          .storeUint(0xfda48b79, 32)
          .storeUint(msg.queryId, 64)
          .endCell();

    let msgCell: Cell = b
      .storeUint(0x18, 6)
      .storeAddress(sender())
      .storeUint(1, 111)
      .storeRef(body)
      .endCell();

    nativeSendMessage(msgCell, SendRemainingValue);
  }

  receive(msg: AdminWithdrawalAllNFTs) {
    if (sender() == myAddress()) {
      let body: Cell = beginCell()
        // .storeUint(0x5fcc3d140000000000000000 + msg.queryId, 96)
        .storeUint(0x5fcc3d14, 32)
        .storeUint(msg.queryId, 64)
        .storeAddress(self.owner)
        .storeAddress(self.owner)
        .storeUint(0, 5)
        .endCell();

      let message: SendParameters = SendParameters{
        to: self.owner, 
        value: ton("0.07"),
        mode: SendIgnoreErrors,
        body: body
      };

      repeat(self.countNfts) {
        self.countNfts = self.countNfts - 1;
        message.to = self.nfts.get(self.countNfts)!!;
        send(message);
      }

      self.nfts = emptyMap();     
      return;
    }

    // require(sender() == myAddress() || context().value >= ton("1") + self.countNfts * ton("0.08"), "Insufficent funds");
    // require(sender() == self.owner || sender() == myAddress(), "Invalid sender");
    require(context().value >= ton("1") + self.countNfts * ton("0.08"), "Insufficent funds");
    require(sender() == self.owner, "Invalid sender");

    let body: Cell = beginCell()
        // .storeUint(0x5fcc3d140000000000000000 + msg.queryId, 96)
        .storeUint(0x5fcc3d14, 32)
        .storeUint(msg.queryId, 64)
        .storeAddress(self.owner)
        .storeAddress(self.owner)
        .storeUint(0, 5)
        .endCell();

    let message: SendParameters = SendParameters{
      to: self.owner, 
      value: ton("0.07"),
      mode: SendIgnoreErrors,
      body: body
    };

    repeat(min(self.countNfts, 253)) {
      self.countNfts = self.countNfts - 1;
      message.to = self.nfts.get(self.countNfts)!!;
      send(message);
    }

    if (self.countNfts > 0) {
      let bodyWithdrawal: Cell = beginCell()
          // .storeUint(0x6339421f0000000000000000 + msg.queryId, 96)
          .storeUint(0x6339421f, 32)
          .storeUint(msg.queryId, 64)
          .endCell();

      send(SendParameters{
        to: myAddress(),
        value: 0,
        mode: SendRemainingBalance,
        body: bodyWithdrawal
      }); 
      return;
    }

    self.nfts = emptyMap();
  }

  get fun profit(): Int { 
    return myBalance() - ton("0.1");
  }

  get fun nfts(): map<Int as uint16, Address> { 
    return self.nfts;
  }
}
