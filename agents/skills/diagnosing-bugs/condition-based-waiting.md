# Condition-based waiting

Arbitrary delays make asynchronous checks slow and flaky. Wait for the event or
state the caller actually needs.

```typescript
async function waitFor<T>(
  condition: () => T | undefined | null | false,
  description: string,
  timeoutMs = 5000,
): Promise<T> {
  const deadline = Date.now() + timeoutMs;

  while (Date.now() <= deadline) {
    const result = condition();
    if (result) return result;
    await new Promise(resolve => setTimeout(resolve, 10));
  }

  throw new Error(`Timed out waiting for ${description} after ${timeoutMs}ms`);
}
```

Requirements:

- evaluate fresh state inside the loop;
- poll slowly enough not to waste CPU;
- use a finite timeout with an actionable failure message; and
- return the value that satisfied the condition when useful.

A fixed delay is appropriate only when elapsed time is the behavior being
verified, such as debounce or retry intervals. First wait for the triggering
condition, then wait for a duration derived from the documented timing, and
explain that relationship in the test.
