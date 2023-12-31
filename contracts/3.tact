import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Token prices must be decimalized for accuracy, so it is the prices that must be adjusted to decimal 1e9.
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  Example formula for amountOfAJettonToSend in B->A swap will be
  (amountOfJettonAOnContract * decimal / amountOfJettonBOnContract) * amountOfTokenBToSwap / decimal

  If smart contract pool doesn't have enough jettons to trade,
  then it should send incoming jettons back to the user. For a clearer explanation,
  let's look at the example we described above (smart contract has 10 of jetton A and 2 of jetton B).
  If user will send 3 jettons B, smart contract should reject the message (because contract does not have 3 * 5 = 15 jettons A)
  and send 3 jettons B back to the user.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).
  
  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/

message(0x7362d09c) TokenNotification {
  queryId: Int as uint64;
  amount: Int as coins;
  from: Address;
  forwardPayload: Slice as remaining;
}

// To simplify the testing process and the specificity of the messages being sent, we decided to add clear default values in this transaction
message(0xf8a7ea5) TokenTransfer {
  queryId: Int as uint64; // should be 0
  amount: Int as coins; // should be amount of jettons to send
  destination: Address; // should be user address / TokenNotification.from
  responseDestination: Address?; // should be myAddress()
  customPayload: Cell?; // should be null
  forwardTonAmount: Int as coins; // should be ton("0.01")
  forwardPayload: Slice as remaining; // should be emptySlice()
}

contract Task3 with Deployable {
  owner: Address;
  aAmount: Int;
  bAmount: Int;
  jettonAddressA: Address;
  jettonAddressB: Address;
  decimal: Int;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
    self.decimal = 1000000000;
  }

  receive(msg: TokenNotification) {
    if (sender() == self.jettonAddressA) {
      if (msg.from == self.owner) {
        self.aAmount = self.aAmount + msg.amount;
        return;
      }

      let amountB: Int = (self.bAmount * self.decimal / self.aAmount) * msg.amount / self.decimal;

      let b1: Builder =  beginCell()
          .storeUint(0x0f8a7ea50000000000000000, 96);
      let b2: Builder =  beginCell()
          .storeUint(0x18, 6);

      if (self.bAmount > amountB) {
        let body: Cell = b1
          .storeCoins(amountB)
          .storeAddress(msg.from)
          .storeAddress(myAddress())
          .storeUint(0x3989680, 29)
          .endCell();

        let msgCell: Cell = b2
          .storeAddress(self.jettonAddressB)
          .storeUint(1, 111)
          .storeRef(body)
          .endCell();

        nativeSendMessage(msgCell, SendRemainingValue);

        self.aAmount = self.aAmount + msg.amount;
        self.bAmount = self.bAmount - amountB;
        return;
      }

      let body: Cell = b1
        .storeCoins(msg.amount)
        .storeAddress(msg.from)
        .storeAddress(myAddress())
        .storeUint(0x3989680, 29)
        .endCell();

      let msgCell: Cell = b2
        .storeAddress(self.jettonAddressA)
        .storeUint(1, 111)
        .storeRef(body)
        .endCell();

      nativeSendMessage(msgCell, SendRemainingValue);
      return;
    }

    if (sender() == self.jettonAddressB) {
      if (msg.from == self.owner) {
        self.bAmount = self.bAmount + msg.amount;
        return;
      }

      let amountA: Int = (self.aAmount * self.decimal / self.bAmount) * msg.amount / self.decimal;

      let b1: Builder =  beginCell()
          .storeUint(0x0f8a7ea50000000000000000, 96);
      let b2: Builder =  beginCell()
          .storeUint(0x18, 6);

      if (self.aAmount > amountA) {
        let body: Cell = b1
          .storeCoins(amountA)
          .storeAddress(msg.from)
          .storeAddress(myAddress())
          .storeUint(0x3989680, 29)
          .endCell();

        let msgCell: Cell = b2
          .storeAddress(self.jettonAddressA)
          .storeUint(1, 111)
          .storeRef(body)
          .endCell();

        nativeSendMessage(msgCell, SendRemainingValue);

        self.bAmount = self.bAmount + msg.amount;
        self.aAmount = self.aAmount - amountA;
        return;
      }
      
      let body: Cell = b1
        .storeCoins(msg.amount)
        .storeAddress(msg.from)
        .storeAddress(myAddress())
        .storeUint(0x3989680, 29)
        .endCell();

      let msgCell: Cell = b2
        .storeAddress(self.jettonAddressB)
        .storeUint(1, 111)
        .storeRef(body)
        .endCell();

      nativeSendMessage(msgCell, SendRemainingValue);
      return;
    }

    throw(0xFFFFFF);
  } 
  
  get fun price(jetton: Address): Int { 
    if (jetton == self.jettonAddressA) {
      return self.bAmount * self.decimal / self.aAmount;
    } else {
      return self.aAmount * self.decimal / self.bAmount;
    }
  }
  
  get fun balance(jetton: Address): Int {
    if (jetton == self.jettonAddressA) {
      return self.aAmount;
    } else {
      return self.bAmount;
    }
  }

}
