import "@stdlib/deploy";

/*
  TASK 3 - Dex contract 
  Create a simple jetton dex contract that trades one pair of token A and B.
  The price of tokens depends on amount of tokens that sc have.
  So, if smartcontract have 10 of token A and 2 of token B, then after sending 1 tokens B you will receive 5 of tokens A.
  
  If user will pool dont have enougth tokens to trade
  (for example someone will send 99999 tokens of B and dex pool have only 10 of tokens A),
  then return sended (tokens B in our example) tokens back to user

  Implement a getter that will give the number of tokens in the pool and
  one more to get price of token A or token B.
  
  Note
  Admin can add token A and token B just by sending then to smartcontract (we need to set initial supply for the pool). 
*/

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
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
  a: Int;
  b: Int;
  jAddressA: Address;
  jAddressB: Address;
  decimal: Int;

  init(admin: Address, newJAddressA: Address, newJAddressB: Address) {
    self.owner = admin;
    self.jAddressA = newJAddressA;
    self.jAddressB = newJAddressB;
    self.a = 0;
    self.b = 0;
    self.decimal = 1000000000;
  }

  receive(msg: TokenNotification) {
    let sender: Address = sender();

    if (sender == self.jAddressA) {
      let price: Int = 0;
      if (self.a > 0) {
        price = self.b / self.a;
      }

      let amountB: Int = price * msg.amount / self.decimal * self.decimal;

      if (amountB > 0 && amountB <= self.b) {
        transfer(self.jAddressB, amountB, context().value, msg);
        self.a = self.a + msg.amount;
        self.b = self.b - amountB;
      } else {
        transfer(self.jAddressA, msg.amount, context().value, msg);
      }

      return;
    }

    if (sender == self.jAddressB) {
      let price: Int = 0;
      if (self.b > 0) {
        price = self.a / self.b;
      }

      let amountA: Int = price * msg.amount / self.decimal * self.decimal;

      if (amountA > 0 && amountA <= self.a) {
        transfer(self.jAddressA, amountA, context().value, msg);
        self.b = self.b + msg.amount;
        self.a = self.a - amountA;
      } else {
        transfer(self.jAddressB, msg.amount, context().value, msg);
      }

      return;
    }

    throw(0xFFFFFF);
  } 
  
  get fun price(token: Address): Int { 
    if (token == self.jAddressA) {
      if (self.a == 0) {
        return 0;
      }
      return self.b / self.a;
    }

    if (token == self.jAddressB) {
      if (self.b == 0) {
        return 0;
      }
      return self.a / self.b;
    }

    return 0;
  }
  
  get fun balance(token: Address): Int { 
    if (token == self.jAddressA) {
      return self.a;
    }

    if (token == self.jAddressB) {
      return self.b;
    }

    return 0;
  }

}

fun transfer(to: Address, amount: Int, value: Int, msg: TokenNotification) {
  send(SendParameters{
    to: to,
    value: 0,
    mode: SendRemainingValue,
    body: TokenTransfer {
      queryId: msg.queryId,
      amount: amount,
      destination: msg.from,
      responseDestination: msg.from,
      customPayload: null,
      forwardTonAmount: value,
      forwardPayload: msg.forwardPayload
    }.toCell()
  });
}
