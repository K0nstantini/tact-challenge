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

    it.skip('test-1', async () => {
        let res = await sendOwnershipAssigned(nft1, owner.address, toNano("0.1"));
        expect(res.transactions).toHaveTransaction({
            from: nft1.address,
            to: task5.address,
            success: true,
        });
        await sendOwnershipAssigned(nft2, owner.address, toNano("0.1"));
        await sendOwnershipAssigned(nft3, owner.address, toNano("0.1"));

        console.log(`nft-1: ${nft1.address}`);
        console.log(`nft-2: ${nft2.address}`);
        console.log(`nft-3: ${nft3.address}`);
        console.log(`nft-4: ${nft4.address}`);
        console.log(`nft-5: ${nft5.address}`);

        // let nfts = await task5.getNfts();
        // console.log(nfts);
 
        let balance = await task5.getBalance();
        console.log(`balance: ${balance}`);

        res = await sendOwnershipAssigned(nft4, random.address, toNano("2.1"));
        // console.log(res.transactions);

        balance = await task5.getBalance();
        console.log(`balance: ${balance}`);

        res = await sendOwnershipAssigned(nft5, random.address, toNano("5"));
        // console.log(res.transactions);

        balance = await task5.getBalance();
        console.log(`balance: ${balance}`);

        await sendOwnershipAssigned(nft3, random.address, toNano("1"));
        balance = await task5.getBalance();
        console.log(`balance: ${balance}`);

        // nfts = await task5.getNfts();
        // console.log(nfts);

        let profit = await task5.getProfit();
        console.log(`Profit before withdraw: ${profit}`);

        await sendAdminWithdrawalProfit();
        // profit = await task5.getProfit();
        // console.log(`Profit after withdraw: ${profit}`);

        balance = await task5.getBalance();
        console.log(`balance: ${balance}`);

        res = await sendAdminWithdrawalAllNFTs();
        expect(res.transactions).toHaveTransaction({
            from: owner.address,
            to: task5.address,
            success: true,
        });
        // nfts = await task5.getNfts();
        // console.log(nfts);

    });

    it('test-2', async () => {
        await sendOwnershipAssigned(nft1, owner.address, toNano("0.1"));
        await sendOwnershipAssigned(nft2, owner.address, toNano("0.1"));
        await sendOwnershipAssigned(nft3, owner.address, toNano("0.1"));

        console.log(`nft-1: ${nft1.address}`);
        console.log(`nft-2: ${nft2.address}`);
        console.log(`nft-3: ${nft3.address}`);
        console.log(`nft-4: ${nft4.address}`);
        console.log(`nft-5: ${nft5.address}`);

        let nfts = await task5.getNfts();
        console.log(nfts);

        await sendOwnershipAssigned(nft4, random.address, toNano("2.1"));
        nfts = await task5.getNfts();
        console.log(nfts);

        await sendOwnershipAssigned(nft5, random.address, toNano("5"));
        nfts = await task5.getNfts();
        console.log(nfts);

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
            value: toNano("2")
        }, {
            $$type: 'AdminWithdrawalAllNFTs',
            queryId: 0n,
        })
    }

});



