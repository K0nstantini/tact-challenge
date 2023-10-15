import { Blockchain, SandboxContract, TreasuryContract } from '@ton-community/sandbox';
import { Address, beginCell, toNano } from 'ton-core';
import { Task5 } from '../wrappers/Task5';
import '@ton-community/test-utils';

describe('Task5', () => {
    let blockchain: Blockchain;
    let task5: SandboxContract<Task5>;
    let owner: SandboxContract<TreasuryContract>;
    let random: SandboxContract<TreasuryContract>;
    let nft1: SandboxContract<TreasuryContract>;
    let nft2: SandboxContract<TreasuryContract>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        owner = await blockchain.treasury('owner');
        random = await blockchain.treasury('random');
        nft1 = await blockchain.treasury('nft1');
        nft2 = await blockchain.treasury('nft2');

        task5 = blockchain.openContract(await Task5.fromInit(
            1n, owner.address
        ));
        const deployer = await blockchain.treasury('deployer');
        const deployResult = await task5.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );
        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: task5.address,
            deploy: true,
            success: true,
        });
    });

    it('test', async () => {
        let res = await sendOwnershipAssigned(nft1, owner.address);
        expect(res.transactions).toHaveTransaction({
            from: nft1.address,
            to: task5.address,
            success: true,
        });

        let balance = await task5.getProfit();
        console.log(`balance: ${balance}`);

        res = await sendOwnershipAssigned(nft2, random.address);
        expect(res.transactions).toHaveTransaction({
            from: nft2.address,
            to: task5.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task5.address,
            success: true,
        });

        balance = await task5.getProfit();
        console.log(`balance: ${balance}`);


    });

    async function sendOwnershipAssigned(sender: SandboxContract<TreasuryContract>, owner: Address) {
        return await task5.send(sender.getSender(), {
            value: toNano('2.2')
        }, {
            $$type: 'OwnershipAssigned',
            queryId: 0n,
            prevOwner: owner,
            forwardPayload: beginCell().endCell()
        })
    }

});



