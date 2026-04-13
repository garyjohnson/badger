Review the diff of your changes against main for test coverage:

- For each piece of new or changed **logic** (conditionals, computations, state transitions, error handling, validation), verify that the behavior is tested.
- Bug fixes and defensive guards especially need regression tests — they encode behavior that was previously wrong.
- Tests must specifically exercise the changed behavior. A test file merely existing for the module is not enough.
- Distinguish between **decisions** (if/else, switch, computed values, data transformations — these need tests) and **declarations** (simple assignments, layout, config wiring — these do not).
- Do not waive coverage requirements because the project is new or the change seems small.

If you find untested logic, write the tests before proceeding.
