const std = @import("std");
const jit = @import("jit");
pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const joined: []const u8 = try std.mem.join(allocator, "", args[1..]);
    defer allocator.free(joined);

    if (args.len < 2) {
        @panic("Usage: brainfuck [code...]\n");
    }
    const trimmed = std.mem.trim(u8, joined, &[_]u8{ 0, ' ', '\n', '\t', '\r' });
    const tokens = try jit.parseAlloc(allocator, trimmed);
    defer allocator.free(tokens);
    try jit.run(tokens);
}
