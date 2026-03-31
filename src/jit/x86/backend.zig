const std = @import("std");
const cg = @import("codegen.zig");
const AssemblerContext = @import("../context.zig").AssemblerContext;
const JumpCondition = @import("codegen.zig").JumpCondition;
const Register = @import("codegen.zig").Register;

pub const COMPARE_JUMP_SIZE = 5;

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
    try cg.add_ptr(ctx, Register.rsi, value * 8);
}

pub fn emitDecPtr(ctx: *AssemblerContext, value: u8) !void {
    try cg.sub_ptr(ctx, Register.rsi, value * 8);
}

pub fn emitPutc(ctx: *AssemblerContext) !void {
    try cg.push(ctx, Register.rsi);
    try cg.push(ctx, Register.rbx);
    try cg.mov_immediate(ctx, Register.rdi, @intFromPtr(ctx.writer));
    try cg.mov_from_ptr(ctx, Register.rsi, Register.rsi);
    try cg.mov_immediate(ctx, Register.rax, @intFromPtr(&putc));
    try cg.call(ctx, Register.rax);
    try cg.pop(ctx, Register.rbx);
    try cg.pop(ctx, Register.rsi);
}

fn putc(writer: *std.Io.Writer, c: u8) callconv(.c) void {
    writer.print("{c}", .{c}) catch {};
}

pub fn emitGetc(ctx: *AssemblerContext) !void {
    try cg.push(ctx, Register.rsi);
    try cg.push(ctx, Register.rbx);
    try cg.mov_immediate(ctx, Register.rdi, @intFromPtr(ctx.reader));
    try cg.mov_immediate(ctx, Register.rax, @intFromPtr(&getc));
    try cg.call(ctx, Register.rax);
    try cg.pop(ctx, Register.rbx);
    try cg.pop(ctx, Register.rsi);
    try cg.mov_to_ptr(ctx, Register.rsi, Register.rax);
}

fn getc(reader: *std.Io.Reader) callconv(.c) u8 {
    return reader.takeByte() catch 0;
}

pub fn emitLParen(ctx: *AssemblerContext) !u64 {
    try cg.mov_from_ptr(ctx, Register.rax, Register.rsi);
    try cg.cmp(ctx, Register.rax, Register.rbx);
    return cg.jump(ctx, JumpCondition.equal, 0);
}

pub fn emitRParen(ctx: *AssemblerContext) !u64 {
    try cg.mov_from_ptr(ctx, Register.rax, Register.rsi);
    try cg.cmp(ctx, Register.rax, Register.rbx);
    return cg.jump(ctx, JumpCondition.notEqual, 0);
}

test {
    _ = cg;
}
