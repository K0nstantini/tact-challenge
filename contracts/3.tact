import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  If smart contract pool doesn't have enough jettons to trade
  (for example someone sends 99999 jettons of B, but dex pool only has 10 of jettons A),
  then sent incoming jettons (B, in our example) back to the sender.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).
  
  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/

message(0x7362d09c) JettonNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
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

  receive(msg: JettonNotification) {
    let sender: Address = sender();


    if (sender == self.jettonAddressA) {
      if (msg.from == self.owner) {
        self.aAmount = self.aAmount + msg.amount;
        return;
      }

      let price: Int = 0;
      if (self.aAmount > 0) {
        price = self.bAmount * self.decimal / self.aAmount;
      }

      let amountB: Int = price * msg.amount / self.decimal;

      if (amountB > 0 && amountB <= self.bAmount) {
        self.transfer(self.jettonAddressB, amountB, context().value, msg);
        self.aAmount = self.aAmount + msg.amount;
        self.bAmount = self.bAmount - amountB;
      } else {
        self.transfer(self.jettonAddressA, msg.amount, context().value, msg);
      }

      return;
    }

    if (sender == self.jettonAddressB) {
      if (msg.from == self.owner) {
        self.bAmount = self.bAmount + msg.amount;
        return;
      }

      let price: Int = 0;
      if (self.bAmount > 0) {
        price = self.aAmount * self.decimal / self.bAmount;
      }

      let amountA: Int = price * msg.amount / self.decimal;

      if (amountA > 0 && amountA <= self.aAmount) {
        self.transfer(self.jettonAddressA, amountA, context().value, msg);
        self.bAmount = self.bAmount + msg.amount;
        self.aAmount = self.aAmount - amountA;
      } else {
        self.transfer(self.jettonAddressB, msg.amount, context().value, msg);
      }

      return;
    }

    throw(0xFFFFFF);
  } 
  
  get fun price(jetton: Address): Int { 
    if (jetton == self.jettonAddressA && self.aAmount > 0) {
      return self.bAmount / self.aAmount;
    }

    if (jetton == self.jettonAddressB && self.bAmount > 0) {
      return self.aAmount / self.bAmount;
    }

    return 0;
  }
  
  get fun balance(jetton: Address): Int {
    if (jetton == self.jettonAddressA) {
      return self.aAmount;
    }

    if (jetton == self.jettonAddressB) {
      return self.bAmount;
    }

    return 0;
  }

  fun transfer(to: Address, amount: Int, value: Int, msg: JettonNotification) {
    send(SendParameters{
      to: to,
      value: 0,
      mode: SendRemainingValue,
      body: JettonTransfer {
        queryId: msg.queryId,
        amount: amount,
        destination: msg.from,
        responseDestination: msg.from,
        customPayload: null,
        forwardTonAmount: 0,
        forwardPayload: msg.forwardPayload
      }.toCell()
    });
    
  }

}
