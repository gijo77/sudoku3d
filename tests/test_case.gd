extends RefCounted
## Minimal base class for tests. Subclass and add `test_*` methods.

var failures: Array[String] = []
var assertions := 0

func assert_true(cond: bool, msg: String = "") -> void:
	assertions += 1
	if not cond:
		failures.append("assert_true failed: " + msg)

func assert_eq(actual, expected, msg: String = "") -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [msg, str(expected), str(actual)])
