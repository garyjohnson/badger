Review the tests you wrote or modified for validity. A test that passes today but would still pass if you introduced a bug is worse than no test — it gives false confidence.

Check for these antipatterns:

- **Vacuous assertions**: Asserting on values that are always true regardless of the code under test.
- **Tautologies**: Tests that assert the code does what it does (e.g., calling the function and asserting the return matches calling the function again).
- **Missing assertions**: Test functions that exercise code but never assert anything.
- **Mocked into meaninglessness**: Mocks that replace so much of the system that the test validates the mock setup, not the code.
- **Wrong granularity**: A test that only checks a top-level "success" boolean when the real risk is in the details of what was produced.
- **Copy-paste tests**: Tests copied from another case where only the name changed but the assertions still check the old behavior.

For each test, ask: "If I introduced a bug in the code this test covers, would this test catch it?" If the answer is no, fix the test.
