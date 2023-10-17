import "@stdlib/deploy";

/*
  TASK 4 - NFT locker
  Implement a smart contract that will lock NFT for a period of time specified by the owner.
  Smart conrtact should contain logic to process following messages and getters: 

  Messages: 
  * OwnershipAssigned
   - Recives nft + time (in a forwardPayload message as uint32) for which this nft will be locked + address of the sender of the nft (prevOwner).
   - If the smart contract already holds an nft then return the incoming nft back to the sender
  * NftWithdrawal
   - Request withdrawal of the locked nft
   - If sender is not the owner (that came from OwnershipAssigned as prevOwner address) then throw "Invalid sender" 
   - If time has not passed then send message back to the sender with the comment "NFT is still locked" according to the TON's "message with text comment" standard 
   - Otherwise (all good) send the locked nft back to the owner with all the remaining TON balance
   Note that the order of checks is important
   (in case: "sender is not the owner" and "time has not passed" at the same time, "Invalid sender" error takes priority)

  Getters:
  * time
   - get how much lock time is left
  * nft
   - get the address of the locked nft 
  * owner
   - get the owner of the locked nft (that came from OwnershipAssigned as prevOwner)
*/

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

message NftWithdrawal {
  queryId: Int as uint64;
  nftAddress: Address;
}

struct Nft {
  address: Address;
  owner: Address;
  time: Int as uint32;
}

contract Task4 with Deployable {
  seed: Int as uint128;
  nft: Nft?;
  
  init(seed: Int) {
    self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address
  }

  receive(msg: OwnershipAssigned) {
    if (self.nft == null) {
      let time: Int = now() + msg.forwardPayload.loadUint(32);
      self.nft = Nft {
        address: sender(),
        owner: msg.prevOwner,
        time: time
      };
    } else {
      let body: Cell = beginCell()
      .storeUint(0x5fcc3d14, 32)
      .storeUint(msg.queryId, 64)
      .storeAddress(msg.prevOwner)
      .storeAddress(myAddress())
      .storeInt(0, 1)
      .storeCoins(0)
      .storeSlice(emptySlice())
      .endCell();

      // let body: Cell = Transfer {
      //     queryId: msg.queryId,
      //     newOwner: msg.prevOwner,
      //     responseDestination: msg.prevOwner,
      //     customPayload: null,
      //     forwardAmount: 0,
      //     forwardPayload: emptySlice()
      //   }.toCell();

      send(SendParameters {
        to: sender(),
        value: 0,
        mode: SendRemainingValue,
        body: body
      });
    }
  }

  receive(msg: NftWithdrawal) {
    require(self.nft != null, "NFT not fount");
    let nft: Nft = self.nft!!;
    require(nft.address == msg.nftAddress, "Invalid NFT address");
    require(nft.owner == sender(), "Invalid sender");

    if (nft.time <= now()) {

      send(SendParameters {
          to: msg.nftAddress,
          value: 0,
          mode: SendRemainingValue,
          body: Transfer {
            queryId: msg.queryId,
            newOwner: sender(),
            responseDestination: sender(),
            customPayload: null,
            forwardAmount: 0,
            forwardPayload: emptySlice()
          }.toCell()
        });

    self.nft = null;

    } else {
      send(SendParameters{
        to: sender(),
        value: 0, 
        mode: SendRemainingValue, 
        body: "NFT is still locked".asComment()
      });

    }

  }

  get fun time(): Int {
    if (self.nft != null) {
      return max((self.nft!!).time - now(), 0);
    }
      return 0;
  }

  get fun nft(): Address? {
    if (self.nft != null) {
      return (self.nft!!).address;
    }
    return null;
  }

  get fun owner(): Address? {
    if (self.nft != null) {
      return (self.nft!!).owner;
    }
    return null;
  }
}