const std = @import("std");
const builtin = @import("builtin");
const context = @import("context.zig");
const Token = @import("frontend").Token;
pub const Runner = @import("runner.zig");

const arch_backend = switch (builtin.target.cpu.arch) {
    .x86, .x86_64 => @import("x86/backend.zig"),
    .arm, .aarch64 => @import("arm/backend.zig"),
    else => @compileError("cpu arch not supported for jit-compilation"),
};

pub fn compile(gpa: std.mem.Allocator, program: []const Token, writer: *std.Io.Writer, reader: *std.Io.Reader) !context.AssemblerContext {
    var ctx = context.AssemblerContext.init(gpa, writer, reader, 64 * 1024);

    try arch_backend.emitStart(&ctx);

    for (program) |token| {
        switch (token) {
            .plus => |add| try arch_backend.emitAddImmediate(&ctx, add),
            .minus => |subtract| try arch_backend.emitSubImmediate(&ctx, subtract),
            .inc => |increment| try arch_backend.emitIncPtr(&ctx, increment),
            .dec => |decrement| try arch_backend.emitDecPtr(&ctx, decrement),
            .putc => try arch_backend.emitPutc(&ctx),
            .getc => try arch_backend.emitGetc(&ctx),
            .lparen => {
                const jmp_loc = try arch_backend.emitLParen(&ctx);
                try ctx.jump_stack.append(ctx.allocator, jmp_loc);
            },
            .rparen => {
                const lparen_loc = ctx.jump_stack.pop() orelse unreachable;
                const rparen_loc = try arch_backend.emitRParen(&ctx);
                try ctx.update_jump(lparen_loc, rparen_loc);
                try ctx.update_jump(rparen_loc, lparen_loc - arch_backend.COMPARE_JUMP_SIZE);
            },
        }
    }

    try arch_backend.emitEnd(&ctx);

    return ctx;
}

test {
    _ = context;
    _ = arch_backend;
}
