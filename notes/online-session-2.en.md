[简体中文](online-session-2.md) · [Exercise log](README.en.md)

# Online Session 2 | Technical Q&A notes

Based on the Builder Camp FAQ and the official Reactive Omni documentation.

## 1. Check that the Reactive contract can execute after deployment

I would confirm the deployment transaction and contract address on Lasna, then check the Reactive contract's own lREACT balance and any debt recorded by the system contract. The deployer's balance does not fund the contract by itself. I would then send a controlled origin-chain transaction to verify the subscription and callback. In Omni, `onlySystem` restricts who can call `react()`, and `requestCallbackV_1_0` requests a callback.

## 2. Check the event log when `react()` does not run

I would open the origin-chain transaction receipt, confirm that it contains the expected event, and compare the chain ID, emitting contract address and `topic0` with the subscription. For an ERC-20 transfer, the token contract emits the event. To filter for transfers from a particular wallet, check `topic1`. The command `cast keccak "Transfer(address,address,uint256)"` computes `topic0`.

## 3. Use `CallbackRequested` to locate the callback failure

I would start with the logs of the Lasna execution transaction. If there is no `CallbackRequested` event, I would check the branch taken in `react()` and the request parameters. If the request was emitted, I would look for the callback transaction on the destination chain. For `NotAuthorized`, check the actual caller and the destination chain's Callback Proxy. For `CallbackNotAuthorized`, check which Reactive contract the receiving contract is configured to trust.

## References

- [Builder Camp FAQ](https://github.com/ethpanda-org/reactive-builder-camp/blob/main/docs/faq.md)
- [Reactive contracts](https://dev.reactive.network/reactive-contracts)
- [Callback contracts](https://dev.reactive.network/callback-contracts)
