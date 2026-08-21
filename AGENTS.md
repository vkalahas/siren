# Agent Guidelines

## Commit Guidelines

All commits in this repository must strictly adhere to the following rules:

### 1. Conventional Commits
Use the [Conventional Commits](https://www.conventionalcommits.org/) specification for all commit messages.

Format:
```
<type>(<optional scope>): <description>

[optional body]

[optional footer(s)]
```

Common types:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc.)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `build`: Changes that affect the build system or external dependencies
- `ci`: Changes to CI configuration files and scripts
- `chore`: Other changes that don't modify src or test files

### 2. Atomic Commits
- **Single logical change**: Each commit should encapsulate exactly one task, bug fix, or feature.
- **Always buildable & testable**: Every individual commit should leave the codebase in a working, compiling, and test-passing state.
- **Do not mix concerns**: Avoid combining refactoring, formatting, and feature additions into a single commit. Split them into distinct, sequential commits.
