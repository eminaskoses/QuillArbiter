# Glossary

## Terms

**Arbitration** - The process of resolving disputes through neutral third parties (jurors) instead of traditional courts.

**Commit-Reveal** - A two-phase voting mechanism where voters first submit encrypted votes (commit), then reveal them later to prevent vote manipulation.

**Dispute** - A disagreement between two parties that requires arbitration to resolve.

**Escrow** - Funds held by a smart contract until dispute resolution completes.

**Evidence** - Digital proof submitted by dispute parties, stored encrypted off-chain with on-chain hash commitments.

**Juror** - A staked participant who votes on dispute outcomes.

**Plaintiff** - The party who files a dispute.

**Defendant** - The party against whom a dispute is filed.

**Reputation** - A score tracking juror voting accuracy and participation.

**Ruling** - The final decision on a dispute based on jury votes.

**Slashing** - Penalty mechanism where jurors lose stake for misconduct.

**Stake** - ETH locked by jurors as collateral for participation.

**Verdict** - The outcome determination (PlaintiffWins, DefendantWins, or Draw).

**VRF (Verifiable Random Function)** - Chainlink's cryptographically secure randomness for jury selection.

## Contract Names

**DisputeManager** - Manages dispute creation and lifecycle.

**EvidenceVault** - Stores evidence references and hash commitments.

**JuryPool** - Handles juror staking and reputation.

**JurySelection** - Randomly selects jurors via VRF.

**VotingCourt** - Conducts commit-reveal voting.

**RulingExecutor** - Enforces final rulings.

**AppealBoard** - Manages dispute appeals.

## Phases

**Filing** - Initial dispute registration.

**Evidence Submission** - Period for parties to submit proof (default 7 days).

**Jury Selection** - Random selection of eligible jurors.

**Commit Phase** - Jurors submit encrypted votes (default 3 days).

**Reveal Phase** - Jurors reveal their votes (default 2 days).

**Execution** - Ruling is enforced on-chain.

**Appeal** - Optional challenge period (default 7 days).

## Networks

**Optimism** - L2 blockchain where QuillArbiter deploys.

**IPFS** - Decentralized storage for evidence files.

**Arweave** - Permanent decentralized storage alternative.

## Roles

**ADMIN_ROLE** - Can update parameters and withdraw fees.

**SYSTEM_ROLE** - Granted to contracts for inter-contract operations.

**ARBITRATOR_ROLE** - Can process appeals and close disputes.

**VERIFIER_ROLE** - Can verify evidence integrity.

