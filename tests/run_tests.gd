extends SceneTree
## Simple test runner. Run headless:
##   godot --headless -s tests/run_tests.gd
## Runs every `test_*` method of every tests/test_*.gd file. Exit code 1 on failure.

func _init() -> void:
	var total := 0
	var failed := 0
	var dir := DirAccess.open("res://tests")
	var files: Array[String] = []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			files.append(f)
	files.sort()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		var methods: Array[String] = []
		for m in script.get_script_method_list():
			if String(m["name"]).begins_with("test_"):
				methods.append(m["name"])
		methods.sort()
		for name in methods:
			var t = script.new()
			var start := Time.get_ticks_msec()
			t.call(name)
			var ms := Time.get_ticks_msec() - start
			total += 1
			if t.failures.is_empty():
				print("  PASS  %s::%s (%d asserts, %d ms)" % [f, name, t.assertions, ms])
			else:
				failed += 1
				print("  FAIL  %s::%s" % [f, name])
				for msg in t.failures:
					print("        - " + msg)
	print("\n%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)
