# Writing good tests

A test earns its maintenance cost by catching a specific realistic break in
observable behavior.

## Name the break

Before writing the body, answer: **what production change should make this test
fail, and would that change be a bug?** If the answer is only “the source text
changed,” redesign the test around output, side effects, exit status, or a
consumer-visible contract.

Derive expected values independently. Prefer literals and hand-checked fixtures
over computing the expectation with the same helper or algorithm under test.
Test behavior that depends on constants and messages rather than freezing
private structure or wording without a contract.

Test your boundary, not a dependency's documented mechanics. A narrow
characterization test is justified when upstream behavior is surprising and
your code relies on it.

## Exercise the real thing

Prefer real components. Mock only slow, external, nondeterministic, or unsafe
boundaries, and first learn which side effects the real dependency provides.
Mock below any side effect the test relies upon.

Do not assert that a mock exists. Assert the behavior of the component under
test. When arguments, ordering, or call count are part of the boundary contract,
use a specific spy or fake and assert that contract.

Mock responses should mirror the complete relevant production shape, not an
optimistic partial object. If mock setup becomes larger than the behavior under
test, prefer a focused integration test.

Keep cleanup and fixture helpers in test utilities unless the production object
actually owns that lifecycle. Do not add production methods only for tests.

## Mutation check

Before finishing, mentally change the production code in realistic ways:

- choose the wrong branch or argument;
- omit a state change or side effect;
- return an empty/default value; or
- remove validation for an edge case.

At least one test should fail for each relevant mutation. If none does, the
behavior is unprotected or the assertion is tautological.

## Warning signs

- Setup and expectation use the same builder or object.
- The test can fail only through a crash or missing selector.
- It asserts on mock presence, or mock setup dominates the test.
- A production method is called only by tests.
