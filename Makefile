
.PHONY: rebuild retest run build test atlas sloc edit debug cloc random testMap reload

run:
	zig build rl && zig-out/bin/rl

watch:
	zig build rl --watch

continue:
	zig build rl && zig-out/bin/rl --continue

build:
	zig build

release:
	zig build run -Doptimize=ReleaseFast

test:
	zig build test

rebuild:
	find src/* -name "*.zig" | entr -c zig build

retest:
	find src/* -name "*.zig" | entr -c zig build test

random:
	zig build run -- --randomMap

testMap:
	zig build run -- --map testmap.txt

# atlas:
# 	zig build atlas

# sloc:
# 	cloc src/*/*.zig

# edit:
# 	vim -c "args src/*/*.zig" -c "args main.zig Makefile build.zig" -c "b main.zig"

debug:
	gdb zig-out/bin/rl

reload:
	find zig-out/bin/ "rl" | entr -r -c zig-out/bin/rl --continueGame

cloc:
	cloc src/*/*.zig
