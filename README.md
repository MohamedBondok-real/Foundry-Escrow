# Escrow Smart Contract

A Solidity-based Escrow smart contract built with **Foundry** that securely holds ETH between a buyer and a seller until the transaction is approved or a dispute is resolved by a designated arbiter.

This project demonstrates smart contract development, access control, ETH transfers, custom errors, dispute resolution, and unit testing using Foundry.

## Overview

An Escrow contract acts as an intermediary that holds funds until predefined conditions are met.

In this project, the buyer deposits ETH into the contract during deployment. The funds are released to the seller only when both the buyer and seller approve the transaction, provided no dispute has been raised.

If a dispute occurs, a designated arbiter can decide whether the funds should be transferred to the buyer or the seller.

## Features

* **ETH Escrow:** Holds ETH deposited during contract deployment.
* **Mutual Approval:** Requires approval from both buyer and seller before automatically releasing funds.
* **Dispute Management:** Allows either party to raise a dispute.
* **Arbiter-Based Resolution:** Enables the designated arbiter to resolve disputes in favor of either party.
* **Access Control:** Restricts functions to authorized participants.
* **Custom Errors:** Uses custom errors to handle unauthorized access, missing disputes, and failed ETH transfers.
* **Transfer Failure Handling:** Reverts if an ETH transfer fails.
* **Foundry Unit Tests:** Tests core functionality, access control, fund transfers, and failure scenarios.

## How It Works

### 1. Contract Deployment

The contract is deployed with three addresses:

* `buyer` — The party purchasing the product or service.
* `seller` — The party providing the product or service.
* `arbiter` — The authorized party responsible for resolving disputes.

The buyer's funds are deposited into the contract through the payable constructor.

### 2. Mutual Approval

Both parties must approve the transaction:

* `approveByBuyer()` — Allows the buyer to approve the release of funds.
* `approveBySeller()` — Allows the seller to approve the release of funds.

Once both parties approve, the contract automatically transfers the escrowed ETH to the seller, provided no dispute has been raised.

### 3. Raise a Dispute

Either the buyer or seller can call:

`raiseDispute()`

Once a dispute is raised, automatic fund release is prevented, even if both parties have approved.

### 4. Resolve a Dispute

Only the designated arbiter can call:

`resolveDispute(bool _approveForSeller)`

| Parameter | Result                                   |
| --------- | ---------------------------------------- |
| `true`    | Transfers the escrowed ETH to the seller |
| `false`   | Returns the escrowed ETH to the buyer    |

The contract reverts if the ETH transfer fails.

## Smart Contract Functions

| Function               | Description                                                               |
| ---------------------- | ------------------------------------------------------------------------- |
| `constructor()`        | Initializes the buyer, seller, arbiter, and deposited ETH amount          |
| `approveByBuyer()`     | Records the buyer's approval                                              |
| `approveBySeller()`    | Records the seller's approval                                             |
| `raiseDispute()`       | Raises a dispute between the buyer and seller                             |
| `resolveDispute(bool)` | Allows the arbiter to resolve a dispute                                   |
| `releaseIfAgreed()`    | Internally releases funds when both parties approve and no dispute exists |

## Custom Errors

The contract defines the following custom errors:

| Custom Error                  | Purpose                                    |
| ----------------------------- | ------------------------------------------ |
| `Escrow__OnlyBuyer()`         | Caller is not the buyer                    |
| `Escrow__OnlySeller()`        | Caller is not the seller                   |
| `Escrow__OnlyArbiter()`       | Caller is not the arbiter                  |
| `Escrow__NoDisputeRaised()`   | No dispute exists to resolve               |
| `Escrow__TransferFailed()`    | ETH transfer failed                        |
| `Escrow__OnlyBuyerOrSeller()` | Caller is neither the buyer nor the seller |

## Tech Stack

* **Solidity** `^0.8.31`
* **Foundry** — Smart contract development and testing
* **Forge Standard Library** — Testing utilities and cheatcodes

## Project Structure

```text
.
├── src/
│   └── Escrow.sol
├── test/
│   └── Escrow.t.sol
├── foundry.toml
├── lib/
├── .gitignore
└── README.md
```

## Getting Started

### Prerequisites

* [Foundry](https://getfoundry.sh/)
* Git

### Clone the Repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd <YOUR_REPOSITORY_NAME>
```

### Build the Project

```bash
forge build
```

### Run Tests

```bash
forge test
```

For detailed execution traces:

```bash
forge test -vvv
```

## Testing

The test suite in `Escrow.t.sol` covers:

* Constructor initialization and initial state
* Buyer and seller access control
* Individual approval behavior
* Automatic fund release after mutual approval
* Approval order independence
* Prevention of automatic release when a dispute is raised
* Dispute raising by buyer and seller
* Arbiter access control
* Dispute resolution in favor of the buyer or seller
* ETH transfer failure scenarios using a `RejectEther` helper contract

The tests use Foundry's `vm.prank`, `vm.expectRevert`, and assertion utilities to simulate different participants and verify contract behavior.

## Security Considerations

This project is an educational implementation and has not been presented as professionally audited or production-ready.

Before deploying to a live network, consider:

* Reentrancy protection around external ETH transfers.
* State management after successful fund release or dispute resolution.
* Preventing repeated approvals or dispute resolution attempts.
* Validating constructor addresses and deposit requirements.
* The trust assumptions associated with a centralized arbiter.

## Future Improvements

* Emit events for approvals, disputes, and fund releases.
* Add timeout-based refund functionality.
* Improve state management to prevent repeated execution.
* Add fuzz and invariant testing.
* Explore decentralized dispute resolution mechanisms.

## Author

**Mohamed Bondok**

Computer Science Student | Solidity & Blockchain Developer

---

If you find this project interesting, feel free to explore the code and tests!
