const std = @import("std");

pub const AssemblerContext = struct {
    allocator: std.mem.Allocator,
    binary: std.ArrayList(u8),
    tape: *i32,

    pub fn init(allocator: std.mem.Allocator, tape: *i32) AssemblerContext {
        return AssemblerContext{
            .allocator = allocator,
            .binary = std.ArrayList(u8).empty,
            .tape = tape,
        };
    }

    pub fn append_u32(ctx: *AssemblerContext, value: u32) !void {
        const bytes = std.mem.toBytes(value);
        try ctx.binary.appendSlice(ctx.allocator, &bytes);
    }

    pub fn append_u8(ctx: *AssemblerContext, value: u8) !void {
        try ctx.binary.append(ctx.allocator, value);
    }
};
