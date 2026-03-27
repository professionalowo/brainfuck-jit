const std = @import("std");

pub const AssemblerContext = struct {
    allocator: std.mem.Allocator,
    binary: std.ArrayList(u8),
    jump_stack: std.ArrayList(u64),
    tape: []i64,

    pub fn init(allocator: std.mem.Allocator, tapeSize: usize) AssemblerContext {
        const tape = allocator.alloc(i64, tapeSize) catch |err| {
            std.debug.panic("Failed to allocate tape: {}", .{err});
        };
        @memset(tape, 0);

        return AssemblerContext{
            .allocator = allocator,
            .binary = .empty,
            .jump_stack = .empty,
            .tape = tape,
        };
    }

    pub fn deinit(ctx: *AssemblerContext) void {
        ctx.binary.deinit(ctx.allocator);
        ctx.jump_stack.deinit(ctx.allocator);
        ctx.allocator.free(ctx.tape);
    }

    pub fn update_jump(ctx: *AssemblerContext, src_idx: u64, target_idx: u64) !void {
        const offset: i32 = @as(i32, @intCast(target_idx)) - @as(i32, @intCast(src_idx)) - 4;
        const offset_bytes = std.mem.toBytes(offset);
        @memcpy(ctx.binary.items[src_idx .. src_idx + offset_bytes.len], &offset_bytes);
        // std.debug.print("Updated jump at {} to target {} with offset {} and len {}\n", .{ src_idx, target_idx, offset, offset_bytes.len });
    }

    pub fn append_u32(ctx: *AssemblerContext, value: u32) !void {
        const bytes = std.mem.toBytes(value);
        try ctx.binary.appendSlice(ctx.allocator, &bytes);
    }

    pub fn append_u64(ctx: *AssemblerContext, value: u64) !void {
        const bytes = std.mem.toBytes(value);
        try ctx.binary.appendSlice(ctx.allocator, &bytes);
    }

    pub fn append_u8(ctx: *AssemblerContext, value: u8) !void {
        try ctx.binary.append(ctx.allocator, value);
    }
};
