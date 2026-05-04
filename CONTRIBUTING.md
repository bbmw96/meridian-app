# Contributing to MERIDIAN

Thank you for your interest in contributing to MERIDIAN. This document explains how to get involved.

## Code of Conduct

Be respectful, constructive, and collaborative. We will not tolerate harassment of any kind.

## How to Contribute

### Reporting Issues

Before opening an issue, please search existing issues to avoid duplicates.

When reporting a bug, include:
- MERIDIAN version
- iOS version and device model
- Steps to reproduce
- Expected behaviour
- Actual behaviour
- Any relevant MQL queries

### Submitting a Pull Request

1. Fork the repository
2. Create a feature branch from `develop`: `git checkout -b feature/your-feature-name`
3. Make your changes following the conventions below
4. Write or update tests for your change
5. Run the test suite: `make test`
6. Run the linter: `make lint`
7. Commit with a clear message (see Commit Convention)
8. Push and open a pull request against `develop`

All pull requests require at least one approval before merging.

## Conventions

### British English

All code comments, documentation, user-facing strings, and commit messages must use British English spelling:
- colour (not color)
- behaviour (not behavior)
- analyse (not analyze)
- localisation (not localization)
- favour (not favor)
- centre (not center)

### No Em Dashes

Do not use em dashes anywhere: not in comments, not in documentation, not in strings.
Use colons, commas, or hyphens instead.

### Commit Convention

Format: `type(scope): description`

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `style`, `perf`

Examples:
- `feat(mql): add ANALYSE statement with TIMEFRAME clause`
- `fix(currency): handle missing rate gracefully when pair is unknown`
- `docs(readme): update getting started section for Xcode 16`
- `test(ios): add unit tests for DomainScanner normalisation`

### Code Style

**Swift**: follow the SwiftFormat config at the repo root. Run `make format` before committing.

**Rust**: run `cargo fmt` and `cargo clippy -- -D warnings`.

**Go**: run `gofmt` and `golangci-lint`.

**Python**: run `ruff format` and `ruff check`.

**TypeScript**: run ESLint with the project config.

**Elixir**: run `mix format`.

### Adding a New MQL Statement

1. Add token(s) to `mql/src/token.rs`
2. Add AST node(s) to `mql/src/ast.rs`
3. Implement parser method in `mql/src/parser.rs`
4. Add type-checking rules to `mql/src/typechecker.rs`
5. Emit API instruction(s) in `mql/src/codegen/api_codegen.rs`
6. Add integration test in `mql/tests/integration_tests.rs`
7. Update `mql/MQL_REFERENCE.md`

### Adding a New Localisation Language

1. Create the `.lproj` directory: `ios/MERIDIAN/Resources/{locale-code}.lproj/`
2. Copy `en.lproj/Localizable.strings` as a template
3. Translate every key-value pair into the target language
4. Mark RTL languages in `LanguageEngine.swift`'s `supportedLanguages` list
5. Add the locale code to `project.yml` under `CFBundleLocalizations`
6. Open a pull request with the new file

## Architecture Overview

See the [design specification](docs/superpowers/specs/2026-05-04-meridian-design.md) and the [README](README.md) for the full architecture.

## Licence

By contributing to MERIDIAN, you agree that your contributions will be licensed under the MIT Licence.
