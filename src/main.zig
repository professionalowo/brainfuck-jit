const std = @import("std");
const mem = std.mem;
const process = std.process;
const parser = @import("frontend").Parser;
const interpreter = @import("interpret.zig");
const optimizer = @import("optimizer.zig");
const jit = @import("jit");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = false }){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);

    // if (args.len < 2) @panic("Usage: brainfuck [code...]\n");

    // const joined: []const u8 = try mem.join(allocator, "", args[1..]);
    // defer allocator.free(joined);

    const joined = "++++[-].";

    const trimmed = mem.trim(u8, joined, &[_]u8{ 0, ' ', '\n', '\t', '\r' });
    const tokens = try parser.parseAlloc(allocator, trimmed);
    defer allocator.free(tokens);

    const optimized = try optimizer.optimizeAlloc(allocator, tokens);
    defer allocator.free(optimized);

    var compiled = try jit.compile(allocator, optimized);
    defer compiled.deinit();
    std.debug.print("Compiled binary: {x} \nsize: {} bytes\n", .{ compiled.binary.items, compiled.binary.items.len });

    try jit.Runner.run(compiled.binary.items);

    // const test_bin = [_]u8{ 0xB8, 0x78, 0x56, 0x34, 0x12, 0xC3 };
    // try jit.Runner.run(&test_bin);

    var w = std.fs.File.stdout().writer(&.{});
    const stdout = &w.interface;
    var r = std.fs.File.stdin().reader(&.{});
    const stdin = &r.interface;
    try interpreter.run(optimized, stdout, stdin);
}

test "helloworld" {
    const program = "++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.";
    const expected = "Hello World!\n";

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const dbg_allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL: leaked memory");
    }

    const tokens = try parser.parseAlloc(dbg_allocator, program);
    defer dbg_allocator.free(tokens);

    const optimized = try optimizer.optimizeAlloc(dbg_allocator, tokens);
    defer dbg_allocator.free(optimized);

    var reader = std.Io.Reader.failing;

    var buffer = [_]u8{0} ** 4096;
    var writer = std.Io.Writer.fixed(&buffer);

    try interpreter.run(optimized, &writer, &reader);
    try std.testing.expectEqualStrings(expected, writer.buffer[0..writer.end]);
}
