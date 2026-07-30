---
name: verification-before-completion
description: Require fresh, relevant evidence before claiming that work is complete, fixed, passing, or ready to merge.
---

# Verification before completion

Evidence must precede the claim. Confidence, inspection, and an earlier test run
are not substitutes for verification after the last relevant change.

Before reporting success:

1. **Identify** the command or observation that proves each claim.
2. **Run** the full relevant command after the last relevant edit.
3. **Read** its complete output and exit status; count failures and warnings.
4. **Check** the original requirement or symptom, not merely a proxy.
5. **Report** the claim with the evidence, or report the actual failure and what
   remains unresolved.

| Claim | Required evidence | Insufficient evidence |
|---|---|---|
| Tests pass | Fresh test output with zero failures | A previous run or “should pass” |
| Build succeeds | Fresh build with exit status 0 | A clean linter run |
| Bug is fixed | Original reproducer or regression test now passes | The code changed |
| Regression test is valid | The test was observed failing for the expected reason before the fix and passing after it | A test that only passed |
| Delegated work is complete | Inspect the diff and independently run its checks | The worker's report |
| Requirements are met | Re-read each requirement and map it to code and verification | Tests alone |

Use the narrowest command that proves the behavior while developing, then run
the repository's required broader checks before completion. For documentation,
configuration, or prompt changes, use the strongest available structural or
consumer-level validation and state when no executable test exists.

Do not hide partial verification behind positive wording. If a check cannot be
run, name the missing prerequisite, the unverified claim, and any narrower
checks that did run.
