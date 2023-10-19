import "@stdlib/deploy";

/*
  TASK 2 - Proxy contract 
  Create a contract that forwards all messages sent and tokens received 
  to the admin contract (the address will be set in init_store).
  Transaction from proxy contract to admin contrac should contain
    - Address, of ueser who sended trx (should be stored in the body cell).
    - Original message that proxy smart contract recived from user (should be stored in the first ref in the outcoming body).
  Also, if admin contract will bounce message (Bounced / opcode 0x44), then you need to send all ton`s back to user.
  User address will be given in bounced msg body as "sender".
*/

message(0x44) Bounced {
  queryId: Int as uint64;
  sender: Address;
}

contract Task2 with Deployable {
  admin: Address;

  init(admin: Address) {
    self.admin = admin;
  }
  
  receive(msg: Bounced) {
    // require(sender() == self.admin, "1");
    // if (sender() != self.admin) {
      // throw(0xFF);
    // }
    let condition: Bool = sender() == self.admin;
    nativeThrowUnless(100, condition);

    send(SendParameters{
      to: msg.sender,
      value: 0, 
      mode: SendRemainingValue
    });
  }

  receive(msg: Slice) {
    let c: Cell = msg.asCell();
    let body: Cell = beginCell()
      .storeAddress(sender())
      .storeRef(c)
      .endCell();

    let params: SendParameters = SendParameters{
        to: self.admin,
        value: 0,
        mode: SendRemainingValue,
        body: body
    };

    send(params);
  }
}

