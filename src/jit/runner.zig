const std = @import("std");
const AssemblerContext = @import("context.zig").AssemblerContext;

pub fn run(code: []const u8) !void {
    const executable_memory = try std.posix.mmap(
        null,
        code.len,
        .{ .READ = true, .WRITE = true, .EXEC = false },
        .{ .ANONYMOUS = true, .TYPE = .PRIVATE },
        -1,
        0,
    );
    defer std.posix.munmap(executable_memory);

    try std.process.protectMemory(executable_memory, .{ .read = true, .write = false, .execute = true });

    @memcpy(executable_memory, code);

    const func: *const fn () void = @ptrCast(executable_memory);
    func();
}
