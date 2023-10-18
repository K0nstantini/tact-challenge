import { Blockchain, SandboxContract, TreasuryContract } from '@ton-community/sandbox';
import { Address, Slice, beginCell, toNano } from 'ton-core';
import { Task3 } from '../wrappers/Task3';
import '@ton-community/test-utils';
import { log } from 'console';

describe('Task3', () => {
    let blockchain: Blockchain;
    let task3: SandboxContract<Task3>;
    let deployer: SandboxContract<TreasuryContract>;
    let admin: SandboxContract<TreasuryContract>;
    let jettonA: SandboxContract<TreasuryContract>;
    let jettonB: SandboxContract<TreasuryContract>;
    let random: SandboxContract<TreasuryContract>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        admin = await blockchain.treasury('admin');
        jettonA = await blockchain.treasury('jettonA');
        jettonB = await blockchain.treasury('jettonB');
        deployer = await blockchain.treasury('deployer');
        random = await blockchain.treasury('random');

        task3 = blockchain.openContract(await Task3.fromInit(
            admin.address, jettonA.address, jettonB.address
        ));
        const deployResult = await task3.send(
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
            to: task3.address,
            deploy: true,
            success: true,
        });
    });


    it('test', async () => {
        let c = beginCell()
        .storeSlice(beginCell().asSlice())
        .endCell();
        console.log(c);

        let res = await sendNotification(jettonB, random.address, 10n);
        expect(res.transactions).toHaveTransaction({
            from: jettonB.address,
            to: task3.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task3.address,
            to: jettonB.address,
            success: true,
        });

        res = await sendNotification(jettonA, admin.address, 10n);
        expect(res.transactions).toHaveTransaction({
            from: jettonA.address,
            to: task3.address,
            success: true,
        });
        res = await sendNotification(jettonB, admin.address, 2n);
        expect(res.transactions).toHaveTransaction({
            from: jettonB.address,
            to: task3.address,
            success: true,
        });

        let balanceA = await task3.getBalance(jettonA.address);
        let balanceB = await task3.getBalance(jettonB.address);
        expect(balanceA).toEqual(10n);
        expect(balanceB).toEqual(2n);

        res = await sendNotification(jettonB, random.address, 1n);
        expect(res.transactions).toHaveTransaction({
            from: jettonB.address,
            to: task3.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task3.address,
            to: jettonA.address,
            success: true,
        });

        balanceA = await task3.getBalance(jettonA.address);
        balanceB = await task3.getBalance(jettonB.address);
        expect(balanceA).toEqual(5n);
        expect(balanceB).toEqual(3n);

        res = await sendNotification(jettonB, random.address, 10n);
        expect(res.transactions).toHaveTransaction({
            from: jettonB.address,
            to: task3.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task3.address,
            to: jettonB.address,
            success: true,
        });

    });

    async function sendNotification(sender: SandboxContract<TreasuryContract>, from: Address, amount: bigint) {
        return await task3.send(sender.getSender(), {
            value: toNano('0.05')
        }, {
            $$type: 'TokenNotification',
            queryId: 0n,
            amount,
            from,
            forwardPayload: beginCell().endCell()
        })
    }
});


