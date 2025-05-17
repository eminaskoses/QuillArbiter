# Frequently Asked Questions

## General

### What is QuillArbiter?
QuillArbiter is a decentralized protocol for resolving disputes through jury-based arbitration on the Optimism blockchain. It provides trustless, transparent, and enforceable rulings.

### Why Optimism?
Optimism offers low transaction costs and fast finality while maintaining Ethereum's security, making it ideal for frequent dispute-related interactions.

### Is QuillArbiter audited?
The protocol is currently in development. Professional security audits are planned before mainnet deployment.

## For Disputers

### How much does it cost to file a dispute?
The default dispute fee is 0.01 ETH, configurable by governance. This prevents spam while keeping costs accessible.

### What kind of disputes can be filed?
- DAO governance disputes
- NFT ownership/copyright disputes
- Service delivery conflicts
- Escrow-related disagreements
- B2B settlement issues

### How long does dispute resolution take?
Typically 5-7 days:
- Evidence submission: up to 7 days
- Jury selection: ~1 day
- Voting (commit + reveal): 5 days
- Execution: immediate

### Can I appeal a ruling?
Yes, parties can file an appeal within 7 days of ruling execution by paying an appeal fee (default 0.5 ETH).

## For Jurors

### How do I become a juror?
1. Stake minimum 0.1 ETH in JuryPool
2. Maintain minimum reputation of 50
3. Keep your stake active
4. Be randomly selected via Chainlink VRF

### What are the benefits?
- Earn fees from disputes
- Build reputation score
- Participate in decentralized justice
- Help the ecosystem

### What are the risks?
- Stake can be slashed for misconduct
- 30-day lock period on stakes
- Reputation decreases for incorrect votes
- Must participate when selected

### How is my vote kept private?
Votes use commit-reveal scheme:
1. You submit a hash of your vote (commit)
2. Later reveal the actual vote with salt
3. No one can see votes until reveal phase

## Technical

### What blockchain technology is used?
- Solidity smart contracts
- Optimism L2 network
- Chainlink VRF for randomness
- OpenZeppelin security libraries
- IPFS/Arweave for evidence storage

### How is randomness ensured?
Chainlink VRF (Verifiable Random Function) provides cryptographically secure randomness that cannot be manipulated.

### What happens to my evidence?
Evidence is encrypted and stored off-chain (IPFS/Arweave). Only hashes are stored on-chain for integrity verification.

### Can contracts be upgraded?
Admin functions allow parameter updates. Major upgrades would require new deployments with migration paths.

## Economic

### Where do fees go?
- Protocol treasury (governance-controlled)
- Juror rewards (future implementation)
- Development funding
- Bug bounty program

### What prevents Sybil attacks?
- Minimum stake requirement
- Reputation system
- Economic disincentives
- Random selection limits gaming

### What if jurors collude?
- Random selection prevents pre-coordination
- Hidden votes (commit-reveal)
- Reputation at stake
- Economic incentives favor honesty

## Troubleshooting

### Transaction failed - what should I do?
1. Check you have enough ETH for gas
2. Verify you're on correct network
3. Ensure contract hasn't been paused
4. Check error message for specific issue

### My evidence wasn't accepted - why?
Common reasons:
- Evidence hash is invalid (zero hash)
- CID is empty
- Submission deadline passed
- You're not a dispute party
- Dispute status changed

### Can't withdraw stake - why?
Check:
- 30-day lock period has passed
- You have sufficient staked amount
- You're not currently selected as juror
- No pending slashing actions

### Vote reveal failed - what went wrong?
- Wrong salt used
- Verdict doesn't match commit
- Reveal period ended
- Haven't committed a vote

## Integration

### Can I integrate QuillArbiter into my dApp?
Yes! The protocol is designed for integration. See API documentation and integration guides.

### Do you provide SDKs?
JavaScript/TypeScript SDK is in development. Currently use ethers.js directly.

### What events should I listen to?
Key events:
- DisputeFiled
- EvidenceSubmitted
- JurorsSelected
- VotingFinalized
- RulingExecuted

### Is there a testnet?
Yes, deploy to Optimism Sepolia testnet for testing. See deployment guide.

## Governance

### Who controls the protocol?
Currently controlled by multi-sig. Future plans include DAO governance with token holders.

### Can parameters be changed?
Admin can update:
- Fee amounts
- Time periods
- Minimum stakes
- Reputation thresholds

### How are disputes about the protocol handled?
Meta-governance mechanisms are planned for protocol-level disputes.

## Support

### Where can I get help?
- GitHub Discussions
- Discord community
- Documentation
- Email support

### Found a bug?
Report security issues privately to security@quillarbiter.io (placeholder). Other bugs can be reported via GitHub Issues.

### Want to contribute?
See CONTRIBUTING.md for guidelines. We welcome code, documentation, and community contributions!

---

*Don't see your question? Open a discussion on GitHub or join our Discord.*

