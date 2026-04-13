Before submitting, review your changes against main for the following:

- **Correctness**: Trace each changed code path with boundary inputs. Are there logic errors, broken invariants, or off-by-one mistakes?
- **Integration**: Did you update all callers of changed function signatures or data structures? Are there missing changes that should accompany this diff?
- **Security**: Any injection vulnerabilities, hardcoded secrets, auth bypass, or untrusted input at trust boundaries?
- **Error handling**: Are failure modes handled? Will partial failures leave the system in a bad state?
- **Omissions**: Is anything missing that should be part of this change?

If you find issues, fix them before proceeding.
