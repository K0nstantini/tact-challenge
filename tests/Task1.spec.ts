import { Blockchain, SandboxContract, TreasuryContract } from '@ton-community/sandbox';
import { toNano } from 'ton-core';
import { Task1 } from '../wrappers/Task1';
import '@ton-community/test-utils';

describe('Task1', () => {
    let blockchain: Blockchain;
    let task1: SandboxContract<Task1>;
    let random: SandboxContract<TreasuryContract>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        task1 = blockchain.openContract(await Task1.fromInit());
        const deployer = await blockchain.treasury('deployer');
        random = await blockchain.treasury('random');

        const deployResult = await task1.send(
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
            to: task1.address,
            deploy: true,
            success: true,
        });
    });

    it('test', async () => {
        let res = await task1.send(random.getSender(), {
            value: toNano('100')
        }, {
            $$type: 'Add',
            queryId: 0n,
            number: 5n
        })
        // expect(res.transactions).toHaveTransaction({
        //     from: random.address,
        //     to: task1.address,
        //     success: true,
        // });
        
        // let counter = await task1.getCounter();
        // expect(counter).toEqual(5n);
    });
});
