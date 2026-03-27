const std = @import("std");
// const std.posix.PROT = std.posix.PROT;
const AssemblerContext = @import("context.zig").AssemblerContext;

pub fn run(code: []const u8) !void {
    const executable_memory = std.posix.mmap(
        null,
        code.len,
        std.posix.PROT.READ | std.posix.PROT.WRITE | std.posix.PROT.EXEC,
        .{ .ANONYMOUS = true, .TYPE = .PRIVATE },
        -1,
        0,
    ) catch |err| {
        std.debug.panic("Failed to mmap executable memory: {}", .{err});
    };

    @memcpy(executable_memory, code);

    const func: *const fn () void = @ptrCast(executable_memory);
    func();
}
