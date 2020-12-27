# ShadowTokens Smart Contracts
ShadowTokens is a Token Bridge, its smart contracts are inherited from [POA's Token Bridge](https://github.com/poanetwork/token-bridge) project, with a tweaked fee model. Instead of a prorated draw, we use a fixed service fee.

These contracts provide the core functionality for the Token bridge. They implement the logic to relay assests between two EVM-based blockchain networks. The contracts collect bridge validator's signatures to approve and facilitate relay operations.

The Token bridge smart contracts are intended to work with [the bridge process implemented on NodeJS](https://github.com/poanetwork/token-bridge).
Please refer to the bridge process documentation to configure and deploy the bridge.

## Overview

Currently, Token Bridge allows users to transfer assets between the Ethereum, Elastos and Huobi blockchain ecosystem.

And the contracts support four types of relay operations:
* Tokenize the native coin in one blockchain network (Home) into an ERC20 token in another network (Foreign).
* Swap a token presented by an existing ERC20 contract in a Foreign network into an ERC20 token in the Home network, where one pair of bridge contracts corresponds to one pair of ERC20 tokens.
* to mint new native coins in Home blockchain network from a token presented by an existing ERC20 contract in a Foreign network.
* Transfer arbitrary data between two blockchain networks as so the data could be interpreted as an arbitrary contract method invocation.

### Contracts

* ELA-ETH Bridge

  * Mainnet

    ```
    ELA-ETH Bridge
    [ ELA ] HomeBridge: 0x4490ee96671855BD0a52Eb5074EC5569496c0162 at block 2833892
    [ ETH ] ForeignBridge: 0x4FA2EBF8aC682f30AAfaef1048C86DfD0887f1c8 at block 11140009
    
    [ ELA ] Validator: 0x2823B7Ae073cbd74458263328e89386B4e87a477 (BridgeValidators)
    [ ETH ] Validator: 0xf471f4bEED9C74C70ce7Ac4810B8C17922329150 (BridgeValidators)
    
    ELA->ETH (Native To ERC20) 
    [ ELA ] Bridge Mediator: 0xE235CbC85e26824E4D855d4d0ac80f3A85A520E4
    [ ETH ] Bridge Mediator: 0x88723077663F9e24091D2c30c2a2cE213d9080C6
    [ ETH ] ELA ERC677 Token: 0xe6fd75ff38Adca4B97FBCD938c86b98772431867
    
    ETH->ELA (Native To ERC20)
    [ ETH ] Bridge Mediator: 0xf127003ea39878EFeEE89aA4E22248CC6cb7728E
    [ ELA ] Bridge Mediator: 0x314dfec1Fb4de1e0Be70F260d0a065E497f7E2eB
    [ ELA ] ETH ERC677 Token: 0x802c3e839E4fDb10aF583E3E759239ec7703501e
    
    ELA->ETH (Multi Amb ERC to ERC677)
    [ ETH ] Bridge Mediator: 0x6Ae6B30F6bb361136b0cC47fEe25E44B7d58605c
    [ ELA ] Bridge Mediator: 0x0054351c99288D37B96878EDC2319ca006c8B910
    
    ETH->ELA (Multi Amb ERC to ERC677)
    [ ELA ] Bridge Mediator: 0xe6fd75ff38Adca4B97FBCD938c86b98772431867
    [ ETH ] Bridge Mediator: 0xfBec16ac396431162789FF4b5f65F47978988D7f 
    ```

    

* ELA-Heco(Huobi) Bridge

  * Mainnet

    ```
    ELA-HSC Bridge
    [ ELA ] HomeBridge: 0x85AD4E901B8cd61E57Fc0A8Fb0a2ED2Fd4Eb7AFb at block 3807172
    [ HSC ] ForeignBridge: 0x4FA2EBF8aC682f30AAfaef1048C86DfD0887f1c8 at block 606009
    
    ELA->HSC (Native to ERC)
    [ ELA ] Bridge Mediator: 0x74efe86928abe5bCD191f2e6C85b01861ea1C17d
    [ HSC ] Bridge Mediator: 0x5acCF25F5722A6ed0606C02AA5d8cFe27F346e1B
    [ HSC ] ELA ERC677 Token: 0xa1ecFc2beC06E4b43dDd423b94Fef84d0dBc8F5c
    
    HSC->ELA (Native to ERC)
    [ HSC ] Bridge Mediator: 0x4490ee96671855BD0a52Eb5074EC5569496c0162
    [ ELA ] Bridge Mediator: 0x5e071258254c85B900Be01F6D7B3f8F34ab219e7
    [ ELA ] HT ERC677 Token: 0xeceefC50f9aAcF0795586Ed90a8b9E24f55Ce3F3
    
    ELA->HSC (Multi Amb ERC to ERC677)
    [ HSC ] Bridge Mediator: 0x3394577F74B86b9FD4D6e1D8a66c668bC6188379
    [ ELA ] Bridge Mediator: 0x59F65A3913F1FFcE7aB684bd8c24ba3790bD376B
    
    HSC->ELA (Multi Amb ERC to ERC677)
    [ ELA ] Bridge Mediator: 0x6683268d72eeA063d8ee17639cC9B7C317d1734a
    [ HSC ] Bridge Mediator: 0x323b5913dadd3e61e5242Fe44781cb7Dd4BE7EB8
    ```

    

* Heco(Huobi)-ETH Bridge

  * Mainnet

    ```
    HSC-ETH Bridge
    [ HSC ] HomeBridge: 0x74efe86928abe5bCD191f2e6C85b01861ea1C17d at block 716699
    [ ETH ] ForeignBridge: 0x455d0Ce69b67805Dda4d0300f7102148Dd529e3A at block 11533662
    
    [ HSC ] Validator: 0x85AD4E901B8cd61E57Fc0A8Fb0a2ED2Fd4Eb7AFb
    
    HSC->ETH (Native to ERC)
    [ HSC ] Bridge Mediator: 0x8609de58295eDd21bE216C8FD13e270cB27adf05
    [ ETH ] Bridge Mediator: 0x22f3Acd2F30F7Ae79565c0fF91cDd3386893bD92
    [ ETH ] wHT ERC677 Token: 0x6C597FE480714296ff3cad5aDc351b9E621b93B4
    
    ETH->HSC (Native to ERC)
    [ ETH ] Bridge Mediator: 0xEb2aFC9BafD32319CC0c7Db0e117DE24A402054D
    [ HSC ] Bridge Mediator: 0xdC841126328634220e01B98aeF2Ba1729f05C2f2
    [ HSC ] ETH ERC677 Token: 0x5e071258254c85B900Be01F6D7B3f8F34ab219e7
    
    HSC->ETH (Multi Amb ERC to ERC677)
    [ ETH ] Bridge Mediator: 0x8609de58295eDd21bE216C8FD13e270cB27adf05
    [ HSC ] Bridge Mediator: 0x373bfDafa7877C3713b600394E8cec4A8b740632
    
    ETH->HSC (Multi Amb ERC to ERC677)
    [ HSC ] Bridge Mediator: 0xC307D55a6855203d64FbDe6E50fe28797d90cCe9
    [ ETH ] Bridge Mediator: 0xafFf0f760BC03D262725A373727De2976470F1ec
    
    ```



## Deploy

Please to see [here](./deploy/README.md) for deploying the token bridge contracts.



## License

[![License: GPL v3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.



