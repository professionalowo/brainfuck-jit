const std = @import("std");
const AssemblerContext = @import("../context.zig").AssemblerContext;

pub const COMPARE_JUMP_SIZE = 0;

pub fn emitStart(ctx: *AssemblerContext) !void {
    _ = ctx;
}

pub fn emitEnd(ctx: *AssemblerContext) !void {
    _ = ctx;
}

pub fn emitAddImmediate(ctx: *AssemblerContext, value: u8) !void {
    _ = ctx;
    _ = value;
}

pub fn emitSubImmediate(ctx: *AssemblerContext, value: u8) !void {
    _ = ctx;
    _ = value;
}

pub fn emitIncPtr(ctx: *AssemblerContext, value: u8) !void {
    _ = ctx;
    _ = value;
}

pub fn emitDecPtr(ctx: *AssemblerContext, value: u8) !void {
    _ = ctx;
    _ = value;
}

pub fn emitPutc(ctx: *AssemblerContext) !void {
    _ = ctx;
}

fn putc(writer: *std.Io.Writer, c: u8) callconv(.c) void {
    writer.print("{c}", .{c}) catch {};
}

pub fn emitGetc(ctx: *AssemblerContext) !void {
    _ = ctx;
}

fn getc(reader: *std.Io.Reader) callconv(.c) u8 {
    _ = reader;
    return 0;
}

pub fn emitLParen(ctx: *AssemblerContext) !u64 {
    _ = ctx;
    return 0;
}

pub fn emitRParen(ctx: *AssemblerContext) !u64 {
    _ = ctx;
    return 0;
}
