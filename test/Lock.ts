import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { ERC20 } from '../typechain-types';

describe('MyERC20Contract', function () {
  let myERC20Contract: ERC20;
  let someAddress: SignerWithAddress;

  beforeEach(async function () {
    const ERC20ContractFactory = await ethers.getContractFactory('ERC20');
    const MyERC20Contract = await ERC20ContractFactory.deploy('Hello', 'SYM');
    await MyERC20Contract.deployed();

    someAddress = await ethers.getSigners()[1];
  });

  describe('When I have 10 tokens', function () {
    beforeEach(async function () {
      await myERC20Contract.transfer(someAddress, 10);
    });
  });
});
