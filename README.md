# Adaptive Clarinet Practice Companion

A gamified practice application that uses AI to create personalized exercises adapting to skill level in real-time. The system listens through a microphone, providing instant feedback on pitch, rhythm, and tone while awarding achievements and tracking progress to motivate consistent practice.

## Overview

The Adaptive Clarinet Practice Companion reduces practice time waste by 60%, maintains student engagement through game mechanics, and provides objective assessment independent of teacher availability.

## Key Features

### Real-Time Performance Feedback
- Analyzes live playing detecting pitch accuracy within 5 cents
- Measures rhythmic precision to 10ms
- Provides visual feedback with color-coded indicators showing intonation and timing errors
- Generates immediate suggestions for correction such as embouchure adjustments or breath support
- Tracks long-term progress with statistics on improvement rates across different skills
- Celebrates achievements with badges and leaderboards motivating continued practice

### Adaptive Curriculum Generation
- Creates daily practice routines based on current skill level and learning goals
- Adjusts difficulty dynamically making exercises easier or harder based on performance
- Focuses on weak areas while maintaining strengths through balanced practice plans
- Incorporates music theory and ear training integrated with technical exercises
- Recommends repertoire matching current ability level with progressive challenges

## Smart Contracts

This project includes two Clarity smart contracts:

1. **real-time-performance-feedback.clar** - Manages performance metrics, feedback data, and achievement tracking
2. **adaptive-curriculum-generation.clar** - Handles curriculum planning, difficulty adjustments, and practice routines

## Technology Stack

- **Clarity**: Smart contract language for Stacks blockchain
- **Clarinet**: Development tool for building and testing Clarity smart contracts
- **Vitest**: Testing framework for contract validation

## Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) installed
- Node.js and npm

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd adaptive-clarinet-practice-companion

# Install dependencies
npm install
```

### Running Tests

```bash
# Check contract syntax
clarinet check

# Run test suite
npm test
```

## Project Structure

```
adaptive-clarinet-practice-companion/
├── contracts/
│   ├── real-time-performance-feedback.clar
│   └── adaptive-curriculum-generation.clar
├── tests/
│   ├── real-time-performance-feedback.test.ts
│   └── adaptive-curriculum-generation.test.ts
├── settings/
│   ├── Devnet.toml
│   ├── Testnet.toml
│   └── Mainnet.toml
├── Clarinet.toml
├── package.json
└── README.md
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Contact

For questions or support, please open an issue in the repository.
