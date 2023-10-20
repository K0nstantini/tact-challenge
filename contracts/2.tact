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
    nativeThrowUnless(100, sender() == self.admin);

    let msgCell: Cell = beginCell()
      .storeUint(0x18, 6)
      .storeAddress(msg.sender)
      .storeUint(0, 111)
      .endCell();

    nativeSendMessage(msgCell, SendRemainingValue);
  }

  receive(msg: Slice) {
    let b: Builder = beginCell();

    let body: Cell = b
      .storeAddress(sender())
      .storeRef(msg.asCell())
      .endCell();

    let msgCell: Cell = b
      .storeUint(0x18, 6)
      .storeAddress(self.admin)
      .storeUint(1, 111)
      .storeRef(body)
      .endCell();

    nativeSendMessage(msgCell, SendRemainingValue);
  }
}

