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
    let nft3: SandboxContract<TreasuryContract>;
    let nft4: SandboxContract<TreasuryContract>;
    let nft5: SandboxContract<TreasuryContract>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        owner = await blockchain.treasury('owner');
        random = await blockchain.treasury('random');
        nft1 = await blockchain.treasury('nft1');
        nft2 = await blockchain.treasury('nft2');
        nft3 = await blockchain.treasury('nft3');
        nft4 = await blockchain.treasury('nft4');
        nft5 = await blockchain.treasury('nft5');

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
        console.log(`nft-1: ${nft1.address}\nnft-2: ${nft2.address}\nnft-3: ${nft3.address}\nnft-4: ${nft4.address}\nnft-5: ${nft5.address}`);
        console.log(`contract: ${task5.address}\nowner: ${owner.address}\nrandom: ${random.address}`);
    })


    it('test-1', async () => {
        let res = await sendOwnershipAssigned(nft1, owner.address, toNano("0.1"));
        expect(res.transactions).toHaveTransaction({
            from: nft1.address,
            to: task5.address,
            success: true,
        });
        res = await sendOwnershipAssigned(nft2, owner.address, toNano("0.1"));
        expect(res.transactions).toHaveTransaction({
            from: nft2.address,
            to: task5.address,
            success: true,
        });
        res = await sendOwnershipAssigned(nft3, owner.address, toNano("0.1"));
        expect(res.transactions).toHaveTransaction({
            from: nft3.address,
            to: task5.address,
            success: true,
        });

        // console.log(`nft-2: ${nft2.address}`);
        // console.log(`nft-3: ${nft3.address}`);
        // console.log(`nft-4: ${nft4.address}`);
        // console.log(`nft-5: ${nft5.address}`);

        // let nfts = await task5.getNfts();
        // console.log(nfts);
 
        // let balance = await task5.getBalance();
        // console.log(`balance: ${balance}`);

        res = await sendOwnershipAssigned(nft4, random.address, toNano("2.1"));
        expect(res.transactions).toHaveTransaction({
            from: nft4.address,
            to: task5.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task5.address,
            success: true,
        });
        // console.log(res.transactions);

        // balance = await task5.getBalance();
        // console.log(`balance: ${balance}`);

        res = await sendOwnershipAssigned(nft5, random.address, toNano("5"));
        expect(res.transactions).toHaveTransaction({
            from: nft5.address,
            to: task5.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task5.address,
            success: true,
        });
        // console.log(res.transactions);

        // balance = await task5.getBalance();
        // console.log(`balance: ${balance}`);

        res = await sendOwnershipAssigned(nft4, random.address, toNano("1"));
        expect(res.transactions).toHaveTransaction({
            from: nft4.address,
            to: task5.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task5.address,
            to: nft4.address,
            success: true,
        });
        // balance = await task5.getBalance();
        // console.log(`balance: ${balance}`);

        // let nfts = await task5.getNfts();
        // console.log(nfts);

        let profit = await task5.getProfit();
        expect(profit).toBeGreaterThan(toNano("4"));
        // console.log(`Profit before withdraw: ${profit}`);


        res = await sendAdminWithdrawalProfit();
        expect(res.transactions).toHaveTransaction({
            from: owner.address,
            to: task5.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task5.address,
            to: owner.address,
            success: true,
        });
        profit = await task5.getProfit();
        expect(profit).toEqual(0n);
        // console.log(`Profit after withdraw: ${profit}`);

        // balance = await task5.getBalance();
        // console.log(`balance: ${balance}`);

        let nfts = await task5.getNfts();
        // console.log(nfts);

        res = await sendAdminWithdrawalAllNFTs();
        expect(res.transactions).toHaveTransaction({
            from: owner.address,
            to: task5.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task5.address,
            to: nfts.get(0)!,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task5.address,
            to: nfts.get(1)!,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task5.address,
            to: nfts.get(2)!,
            success: true,
        });
        nfts = await task5.getNfts();
        expect(nfts.size).toEqual(0);
        // console.log(nfts);

    });

    it.skip('test-2', async () => {
        let res = await sendOwnershipAssigned(nft4, random.address, toNano("2.2"));
        expect(res.transactions).toHaveTransaction({
            from: nft4.address,
            to: task5.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task5.address,
            to: nft4.address,
            success: true,
        });

    });

    it.skip('test-3', async () => {
        for (let step = 0; step < 300; step++) {
            await sendOwnershipAssigned(nft1, owner.address, toNano("0.1"));
        }
        let nfts = await task5.getNfts();
        expect(nfts.size).toEqual(300);

        let res = await sendAdminWithdrawalAllNFTs();
        expect(res.transactions).toHaveTransaction({
            from: owner.address,
            to: task5.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task5.address,
            to: nft1.address,
            success: true,
        });
        expect(res.transactions).toHaveTransaction({
            from: task5.address,
            to: task5.address,
            success: true,
        });
        nfts = await task5.getNfts();
        expect(nfts.size).toEqual(0);

    });

    async function sendOwnershipAssigned(sender: SandboxContract<TreasuryContract>, owner: Address, value: bigint) {
        return await task5.send(sender.getSender(), {
            value
        }, {
            $$type: 'OwnershipAssigned',
            queryId: 0n,
            prevOwner: owner,
            forwardPayload: beginCell().endCell()
        })
    }

    async function sendAdminWithdrawalProfit() {
        return await task5.send(owner.getSender(), {
            value: toNano("0.03")
        }, {
            $$type: 'AdminWithdrawalProfit',
            queryId: 0n,
        })
    }

    async function sendAdminWithdrawalAllNFTs() {
        return await task5.send(owner.getSender(), {
            value: toNano("26")
        }, {
            $$type: 'AdminWithdrawalAllNFTs',
            queryId: 0n,
        })
    }

});



