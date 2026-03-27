const std = @import("std");
const cg = @import("codegen.zig");
const AssemblerContext = @import("../context.zig").AssemblerContext;
const JumpContext = @import("../context.zig").JumpContext;
const JumpCondition = @import("codegen.zig").JumpCondition;
const Register = @import("codegen.zig").Register;

pub fn emitStart(ctx: *AssemblerContext) !void {
    try cg.mov_immediate(ctx, Register.rsi, @intFromPtr(ctx.tape.ptr));
    try cg.mov_immediate(ctx, Register.rbx, 0);
}

pub fn emitEnd(ctx: *AssemblerContext) !void {
    try cg.ret(ctx);
}

pub fn emitAddImmediate(ctx: *AssemblerContext, value: u8) !void {
    try cg.mov_from_ptr(ctx, Register.rax, Register.rsi);
    try cg.add(ctx, Register.rax, value);
    try cg.mov_to_ptr(ctx, Register.rsi, Register.rax);
}

pub fn emitSubImmediate(ctx: *AssemblerContext, value: u8) !void {
    try cg.mov_from_ptr(ctx, Register.rax, Register.rsi);
    try cg.sub(ctx, Register.rax, value);
    try cg.mov_to_ptr(ctx, Register.rsi, Register.rax);
}

pub fn emitIncPtr(ctx: *AssemblerContext, value: u8) !void {
    try cg.add_ptr(ctx, Register.rsi, value);
}

pub fn emitDecPtr(ctx: *AssemblerContext, value: u8) !void {
    try cg.sub_ptr(ctx, Register.rsi, value);
}

pub fn emitPutc(ctx: *AssemblerContext) !void {
    try cg.mov_immediate(ctx, Register.rax, @intFromPtr(&putc));
    try cg.call(ctx, Register.rax);
}

fn putc(c: u8) void {
    std.debug.print("{c}", .{c});
}

pub fn emitGetc(ctx: *AssemblerContext) !void {
    try cg.mov_immediate(ctx, Register.rax, 0);
    try cg.mov_immediate(ctx, Register.rax, @intFromPtr(&getc));
    try cg.call(ctx, Register.rax);
}

fn getc() u8 {
    return 'a';
}

pub fn emitLParen(ctx: *AssemblerContext) !void {
    try cg.mov_from_ptr(ctx, Register.rax, Register.rsi);
    try cg.cmp(ctx, Register.rax, Register.rbx);
    const jmp_loc = try cg.jump(ctx, JumpCondition.equal, 0);
    try ctx.push_jump_src(jmp_loc);
}

pub fn emitRParen(ctx: *AssemblerContext) !void {
    try cg.mov_from_ptr(ctx, Register.rax, Register.rsi);
    try cg.cmp(ctx, Register.rax, Register.rbx);
    const jmp_loc = try cg.jump(ctx, JumpCondition.notEqual, 0);
    try ctx.push_jump_target(jmp_loc);
}

test {
    _ = cg;
}
