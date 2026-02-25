const builtin = @import("builtin");
const token = @import("frontend");

const arch_backend = switch (builtin.target.cpu.arch) {
    .x86, .x86_64 => @import("x86/backend.zig"),
    .arm, .aarch64 => @compileError("cpu arch not supported for jit-compilation"),
    else => @compileError("cpu arch not supported for jit-compilation"),
};

pub fn compile(program: token.TokenList) !void {
    arch_backend.compile(program);
}
