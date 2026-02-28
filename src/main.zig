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

    if (args.len < 2) @panic("Usage: brainfuck [code...]\n");

    const joined: []const u8 = try mem.join(allocator, "", args[1..]);
    defer allocator.free(joined);

    const trimmed = mem.trim(u8, joined, &[_]u8{ 0, ' ', '\n', '\t', '\r' });
    const tokens = try parser.parseAlloc(allocator, trimmed);
    defer allocator.free(tokens);

    const optimized = try optimizer.optimizeAlloc(allocator, tokens);
    defer allocator.free(optimized);

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
