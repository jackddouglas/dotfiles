# Codebase design

Prefer interfaces that hide meaningful complexity and keep related changes in
one place. Use the project's established terminology. These concepts are design
lenses, not a requirement to rename services, components, APIs, or boundaries.

## Useful concepts

- **Module:** code with an interface and an implementation, at any useful scale.
- **Interface:** everything callers must know, including ordering, errors,
  configuration, invariants, and performance characteristics.
- **Depth:** useful behavior relative to what callers must learn. Judge this
  by caller complexity, not line counts.
- **Seam:** a place where behavior can be substituted; an **adapter** supplies
  a concrete implementation there.
- **Locality:** how well knowledge, changes, and verification stay concentrated.

## Assess a design

Start with concrete caller needs and observed friction. Consider whether an
interface hides complexity or merely passes it through. A small forwarding
layer can still earn its place through compatibility, ownership, or isolation.

Prefer tests through stable behavioral interfaces. Internal tests can be useful
for complex algorithms or failures that are difficult to isolate from outside.
Choose coverage based on the risks it detects.

Justify abstractions with present needs such as substitution, ownership, or
isolating an external dependency. Multiple adapters are evidence of useful
variation, not a prerequisite for an interface.

## Further guidance

- For dependency and coverage tradeoffs, read [DEEPENING.md](DEEPENING.md).
- When exploring alternative interfaces, read
  [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md).
