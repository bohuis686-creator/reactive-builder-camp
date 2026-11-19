# Reactive Builder Camp

Reactive Builder Camp 的学习笔记与 Solidity 练习。营内练习使用 Ethereum Sepolia 和 Reactive Lasna 测试网。

## 环境准备

- 创建测试专用钱包，领用 Ethereum Sepolia ETH，再按 [Reactive 官方 Faucet 文档](https://dev.reactive.network/reactive-mainnet#reactive-faucet) 换取 Lasna lREACT。
- 安装 [Foundry](https://www.getfoundry.sh/introduction/installation)，运行 `forge --version` 和 `cast --version` 检查安装。
- 学习笔记和打卡放在 [notes/](notes/)。

## Reactive Omni 开发资料

- [Reactive 合约](https://dev.reactive.network/reactive-contracts)
- [回调合约](https://dev.reactive.network/callback-contracts)
- [费用与系统交互](https://dev.reactive.network/economy)
- [Omni 官方示例](https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/omni/src/micro-demos)

合约采用 Omni API。给 `react()` 加上 `onlySystem`，用 `requestCallbackV_1_0` 请求回调。旧版的 `vm`、ReactVM 和 `emit Callback` 不适用于本项目。旧地址 `0x...fffFfF` 仅用于识别 Cron 事件。

公开提交前检查笔记、代码与日志中是否包含助记词、私钥或 API 凭据。
