[English](online-session-2.en.md) · [练习记录](README.md)

# Online Session 2｜技术 Q&A 笔记

依据训练营 FAQ 与 Reactive Omni 官方文档整理。

## 1. 部署成功后，要确认 Reactive 合约真的能接单

我会先在 Lasna 浏览器确认部署交易和合约地址，再查合约自己的 lREACT 余额和系统合约里的欠费记录。部署钱包有余额，不代表 Reactive 合约有余额。确认合约具备执行条件后，再发一笔可控的源链交易，逐步确认订阅和回调是否正常。Omni 版本用 `onlySystem` 限制 `react()` 的调用方，通过 `requestCallbackV_1_0` 发起回调。

## 2. 源链交易成功，但 `react()` 没触发时，先对日志

我会打开源链交易回执，看预期事件有没有发出来，再核对订阅的 chain ID、日志里的发出合约地址和 `topic0`。比如监听 ERC-20 转账，发出事件的是代币合约，不能把转出钱包当成发出合约；如果只监听某个钱包转出的交易，应检查 `topic1`。`topic0` 可以用 `cast keccak "Transfer(address,address,uint256)"` 计算。

## 3. 用 `CallbackRequested` 把回调故障分成两段查

查询 Lasna 执行交易的日志。如果没看到 `CallbackRequested`，先查 `react()` 的条件分支和请求参数；如果已经发出请求，再去目标链找回调交易。目标链出现 `NotAuthorized` 时，核对实际调用方和该链的 Callback Proxy；出现 `CallbackNotAuthorized` 时，核对接收合约配置的 Reactive 合约身份。这样可以区分「没发出请求」和「请求发出后被目标链拒绝」。

## 参考资料

- <https://github.com/ethpanda-org/reactive-builder-camp/blob/main/docs/faq.md>
- <https://dev.reactive.network/reactive-contracts>
- <https://dev.reactive.network/callback-contracts>
