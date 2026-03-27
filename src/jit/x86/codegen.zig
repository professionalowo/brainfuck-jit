const std = @import("std");
const AssemblerContext = @import("../context.zig").AssemblerContext;

pub const Register = enum(u8) {
    rax,
    rcx,
    rdx,
    rbx,
    rsp,
    rbp,
    rsi,
    rdi,
};

pub fn mov_immediate(ctx: *AssemblerContext, reg: Register, value: u64) !void {
    try ctx.append_u8(0x48); // REX.W
    try ctx.append_u8(0xB8 + @intFromEnum(reg)); // MOV r64, imm64
    try ctx.append_u64(value);
}

pub fn mov_from_ptr(ctx: *AssemblerContext, reg: Register, ptr_reg: Register) !void {
    try ctx.append_u8(0x48); // REX.W
    try ctx.append_u8(0x8B); // MOV r64, r/m64
    if (ptr_reg == Register.rsp) {
        try ctx.append_u8(8 * @intFromEnum(reg) + @intFromEnum(ptr_reg));
        try ctx.append_u8(0x24);
    } else if (ptr_reg == Register.rbp) {
        try ctx.append_u8(8 * @intFromEnum(reg) + 0x45);
        try ctx.append_u8(0x0);
    } else {
        try ctx.append_u8(8 * @intFromEnum(reg) + @intFromEnum(ptr_reg));
    }
}

pub fn mov_to_ptr(ctx: *AssemblerContext, ptr_reg: Register, reg: Register) !void {
    try ctx.append_u8(0x48); // REX.W
    try ctx.append_u8(0x89); // MOV r/m64, r64
    if (ptr_reg == Register.rsp) {
        try ctx.append_u8(8 * @intFromEnum(reg) + @intFromEnum(ptr_reg));
        try ctx.append_u8(0x24);
    } else if (ptr_reg == Register.rbp) {
        try ctx.append_u8(8 * @intFromEnum(reg) + 0x45);
        try ctx.append_u8(0x0);
    } else {
        try ctx.append_u8(8 * @intFromEnum(reg) + @intFromEnum(ptr_reg));
    }
}

pub fn call(ctx: *AssemblerContext, reg: Register) !void {
    try ctx.append_u8(0xFF); // CALL r/m64
    try ctx.append_u8(0xD0 + @intFromEnum(reg));
}

pub fn ret(ctx: *AssemblerContext) !void {
    try ctx.append_u8(0xC3); // RET
}

fn jmp(ctx: *AssemblerContext, offset: i32) !u64 {
    try ctx.append_u8(0xE9); // JMP rel32
    const jmp_loc = ctx.binary.items.len;
    try ctx.append_u32(@intCast(offset));
    return jmp_loc;
}

pub const JumpCondition = enum(u8) {
    none,
    equal = 0x74,
    notEqual = 0x75,
};

pub fn jump(ctx: *AssemblerContext, cond: JumpCondition, offset: i32) !u64 {
    var jmp_loc: u64 = 0;
    if (cond == JumpCondition.none) {
        jmp_loc = try jmp(ctx, offset);
        return jmp_loc;
    }
    try ctx.append_u8(0x0F); // Jcc rel32
    try ctx.append_u8(@intFromEnum(cond) + 0x10);
    jmp_loc = ctx.binary.items.len;
    // std.debug.print("Emitting jump with condition {} at location {}\n", .{ cond, jmp_loc });
    try ctx.append_u32(@intCast(offset));
    return jmp_loc;
}

pub fn add(ctx: *AssemblerContext, reg: Register, value: u8) !void {
    try ctx.append_u8(0x48); // REX.W
    try ctx.append_u8(0x83); // ADD r/m64, imm8
    try ctx.append_u8(0xC0 + @intFromEnum(reg));
    try ctx.append_u8(value);
}

pub fn sub(ctx: *AssemblerContext, reg: Register, value: u8) !void {
    try ctx.append_u8(0x48); // REX.W
    try ctx.append_u8(0x83); // SUB r/m64, imm8
    try ctx.append_u8(0xE8 + @intFromEnum(reg));
    try ctx.append_u8(value);
}

pub fn add_ptr(ctx: *AssemblerContext, reg: Register, value: u8) !void {
    try ctx.append_u8(0x48); // REX.W
    try ctx.append_u8(0x83); // ADD r/m64, imm8
    try ctx.append_u8(0xC0 + @intFromEnum(reg));
    try ctx.append_u8(value);
}

pub fn sub_ptr(ctx: *AssemblerContext, reg: Register, value: u8) !void {
    try ctx.append_u8(0x48); // REX.W
    try ctx.append_u8(0x83); // SUB r/m64, imm8
    try ctx.append_u8(0xE8 + @intFromEnum(reg));
    try ctx.append_u8(value);
}

pub fn cmp(ctx: *AssemblerContext, reg1: Register, reg2: Register) !void {
    try ctx.append_u8(0x48); // REX.W
    try ctx.append_u8(0x39); // CMP r/m64, r64
    try ctx.append_u8(0xC0 + 8 * @intFromEnum(reg2) + @intFromEnum(reg1));
}

pub fn push(ctx: *AssemblerContext, reg: Register) !void {
    try ctx.append_u8(0x50 + @intFromEnum(reg)); // PUSH r64
}

pub fn pop(ctx: *AssemblerContext, reg: Register) !void {
    try ctx.append_u8(0x58 + @intFromEnum(reg)); // POP r64
}

test "x86_codegen" {
    var ctx = AssemblerContext.init(std.testing.allocator, 10);
    defer ctx.deinit();

    try mov_immediate(&ctx, Register.rax, 0x12345678);
    try mov_immediate(&ctx, Register.rbx, 0x9ABCDEF0);

    try mov_from_ptr(&ctx, Register.rcx, Register.rsp);
    try mov_to_ptr(&ctx, Register.rsp, Register.rcx);

    try add(&ctx, Register.rax, 5);
    try sub(&ctx, Register.rbx, 10);
    try add_ptr(&ctx, Register.rsi, 3);
    try sub_ptr(&ctx, Register.rsi, 2);

    try call(&ctx, Register.rax);
    _ = try jump(&ctx, JumpCondition.equal, 0x10);

    const expected = [_]u8{
        0x48, 0xB8, 0x78, 0x56, 0x34, 0x12, 0x00, 0x00, 0x00, 0x00, // MOV rax, 0x12345678
        0x48, 0xBB, 0xF0, 0xDE, 0xBC, 0x9A, 0x00, 0x00, 0x00, 0x00, // MOV rbx, 0x9ABCDEF0
        0x48, 0x8B, 0x0C, 0x24, // MOV rcx, [rsp]
        0x48, 0x89, 0x0C, 0x24, // MOV [rsp], rcx
        0x48, 0x83, 0xC0, 0x05, // ADD rax, 5
        0x48, 0x83, 0xEB, 0x0A, // SUB rbx, 10
        0x48, 0x83, 0xC6, 0x03, // ADD rsi, 3
        0x48, 0x83, 0xEE, 0x02, // SUB rsi, 2
        0xFF, 0xD0, // CALL rax
        0x0F, 0x84, 0x10, 0x00, 0x00, 0x00, // JZ offset=16 (rel32)
    };

    try std.testing.expectEqualSlices(u8, &expected, ctx.binary.items);
}
