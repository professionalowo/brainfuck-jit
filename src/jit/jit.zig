const std = @import("std");
const builtin = @import("builtin");
const context = @import("context.zig");
const Token = @import("frontend").Token;

const arch_backend = switch (builtin.target.cpu.arch) {
    .x86, .x86_64 => @import("x86/backend.zig"),
    .arm, .aarch64 => @import("arm/backend.zig"),
    else => @compileError("cpu arch not supported for jit-compilation"),
};

pub fn compile(gpa: std.mem.Allocator, program: []const Token) ![]const u8 {
    var ctx = context.AssemblerContext.init(gpa);
    defer ctx.binary.deinit(gpa);

    for (program) |token| {
        switch (token) {
            .plus => |add| try arch_backend.emitAddImmediate(&ctx, add),
            .minus => |subtract| try arch_backend.emitSubImmediate(&ctx, subtract),
            .inc => |increment| try arch_backend.emitIncPtr(&ctx, increment),
            .dec => |decrement| try arch_backend.emitDecPtr(&ctx, decrement),
            .putc => try arch_backend.emitPutc(&ctx),
            .getc => try arch_backend.emitGetc(&ctx),
            .lparen, .rparen => {}, // handled in a later pass
        }
    }

    return ctx.binary.toOwnedSlice(gpa);
}

test {
    _ = context;
    _ = arch_backend;
}
