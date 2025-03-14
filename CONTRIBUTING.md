# Contributing to QuillArbiter

Thank you for your interest in contributing to QuillArbiter! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive criticism
- Collaborate openly and transparently

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. If not, create a new issue with:
   - Clear description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Node version, etc.)
   - Code samples if applicable

### Suggesting Features

1. Open an issue with the "enhancement" label
2. Describe the feature and its use case
3. Explain how it benefits the project
4. Be open to feedback and discussion

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Write or update tests
5. Ensure all tests pass (`npm test`)
6. Update documentation if needed
7. Commit with clear messages
8. Push to your fork
9. Open a Pull Request

## Development Setup

```bash
# Clone the repository
git clone https://github.com/eminaskoses/QuillArbiter.git
cd QuillArbiter

# Install dependencies
npm install

# Run tests
npm test

# Compile contracts
npm run compile
```

## Coding Standards

### Solidity

- Follow the official Solidity style guide
- Use NatSpec comments for all public functions
- Keep functions focused and small
- Use meaningful variable names
- Include require statements with descriptive messages

Example:
```solidity
/**
 * @notice Stakes ETH to become a juror
 * @dev Minimum stake amount is enforced
 */
function stake() external payable {
    require(msg.value >= minStakeAmount, "Insufficient stake");
    // Implementation
}
```

### JavaScript/TypeScript

- Use ESLint configuration
- Write async/await instead of promises
- Include error handling
- Add comments for complex logic

### Git Commit Messages

Follow conventional commits format:

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `test:` Test additions or modifications
- `refactor:` Code refactoring
- `style:` Formatting changes
- `chore:` Maintenance tasks

Examples:
```
feat: add reputation decay mechanism
fix: correct voting period calculation
docs: update deployment guide
test: add edge cases for JuryPool
```

## Testing Requirements

- All new features must include tests
- Maintain or improve code coverage
- Test both success and failure cases
- Include integration tests for multi-contract interactions

## Documentation

- Update README for user-facing changes
- Add inline code comments for complex logic
- Update API documentation for interface changes
- Include examples in documentation

## Review Process

1. Maintainers review PRs within 48 hours
2. Address review comments promptly
3. PRs require at least one approval
4. All CI checks must pass
5. Squash commits before merging

## Security

- Never commit sensitive information
- Report security vulnerabilities privately
- Follow best practices for smart contract security
- Consider gas optimization
- Add appropriate access controls

## Questions?

- Open a discussion on GitHub
- Join our Discord community
- Check existing documentation

Thank you for contributing to QuillArbiter!

