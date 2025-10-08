const std = @import("std");
const mem = std.mem;
const process = std.process;
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
    const tokens = try jit.parser.parseAlloc(allocator, trimmed);
    defer allocator.free(tokens);

    const optimized = try jit.optimizer.optimizeAlloc(allocator, tokens);
    defer allocator.free(optimized);
    try jit.run(optimized);
}
