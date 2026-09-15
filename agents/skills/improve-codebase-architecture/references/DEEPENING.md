# Deepening

Use these criteria when considering whether combining responsibilities behind
an interface reduces caller complexity.

## Dependencies

- For pure computation, direct tests may be enough. Combining code is useful
  only when the responsibilities belong together.
- For local dependencies, use realistic stand-ins where they preserve the
  behavior under test. Account for differences from production.
- For owned remote services, separate business behavior from transport where
  that improves testing or ownership. Keep integration coverage for the contract.
- For third-party services, an injected adapter can support focused tests.
  Mocks alone do not establish that the real integration works.

## Interfaces and coverage

Introduce an interface when a concrete need justifies it: substitution,
ownership, compatibility, or isolation. Adapter count is evidence, not a gate.

Keep internal test hooks out of the public API unless callers need them.
Prefer behavioral coverage that survives refactoring, while retaining focused
internal tests that detect distinct risks.

When consolidating modules, compare old and new coverage before removing tests.
Delete tests only when they are redundant or cover behavior intentionally removed.
