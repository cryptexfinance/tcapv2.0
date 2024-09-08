# Documentation

The auto-generated documentation from the natspec comments in the contracts can be found [here](./autogen/src/SUMMARY.md).

---

The TCAP token is an overcollateralized ERC20 token that aims to be pegged to the market cap of the crypto market. Users can mint TCAP by depositing ERC20 tokens into vaults as collateral. When collateral is deposited into a vault, the user can pick a "pocket" to deposit the collateral into.

![Architecture](../asset/architecture.png)

A pocket manages user assets and isolates them from other deposits. A base pocket simply stores the collateral and does not allow for any lending for example. The Aave pocket is a more complex pocket that lends the deposited collateral on Aave allowing user's capital to be used more efficiently. This mechanism allows a user to chose what level of additional risk they want to take on, as well as isolate their collateral from other deposits.

## Liquidations

Should a user's health factor drop below the liquidation threshold the user's collateral can be liquidated. Liquidators can buy TCAP tokens on the open market and call the liquidate function. The liquidation process burns the TCAP tokens and sends the underlying collateral (liquidation reward) back to the liquidator. By default only a portion of a user's position can be liquidated which pushes the user's health factor back above the liquidation threshold.

The liquidation mechanism is based on the V1 version of the TCAP token. The calculation of the liquidation reward and derivation of the formula can be found [here](https://medium.com/@voithjm1/tokenomics-of-tcap-ce9da45e1be9). A minimum and maximum health factor is enforced after the liquidation. The minimum health factor is enforced after the liquidation to ensure that the user should not be able to be liquidated again immediately after a liquidation. The maximum health factor is enforced to ensure the user does not suffer from a larger than necessary liquidation reward, as the more TCAP tokens are liquidated by the liquidator, the more profitable the liquidation becomes and the more of the underlying collateral the user loses. In cases where the user cannot be liquidated in a way that keeps their health factor between the minimum and maximum health factor, the entire position can be liquidated to mitigate the risk of bad debt.
