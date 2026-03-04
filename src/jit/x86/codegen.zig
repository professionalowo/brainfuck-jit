const std = @import("std");
const Token = @import("frontend").Token;
const AssemblerContext = @import("../context.zig").AssemblerContext;

pub const Register = enum(u8) {
    eax,
    ecx,
    edx,
    ebx,
    esp,
    ebp,
    esi,
    edi,
};

pub fn mov_immediate(ctx: *AssemblerContext, reg: Register, value: u32) !void {
    try ctx.append_u8(0xB8 + @intFromEnum(reg)); // MOV r32, imm32
    try ctx.append_u32(value);
}

pub fn mov_from_ptr(ctx: *AssemblerContext, reg: Register, ptr_reg: Register) !void {
    try ctx.append_u8(0x8B); // MOV r32, r/m32
    if (ptr_reg == Register.esp) {
        try ctx.append_u8(8 * @intFromEnum(reg) + @intFromEnum(ptr_reg));
        try ctx.append_u8(0x24);
    } else if (ptr_reg == Register.ebp) {
        try ctx.append_u8(8 * @intFromEnum(reg) + 0x45);
        try ctx.append_u8(0x0);
    } else {
        try ctx.append_u8(8 * @intFromEnum(reg) + @intFromEnum(ptr_reg));
    }
}

pub fn mov_to_ptr(ctx: *AssemblerContext, ptr_reg: Register, reg: Register) !void {
    try ctx.append_u8(0x89); // MOV r/m32, r32
    if (ptr_reg == Register.esp) {
        try ctx.append_u8(8 * @intFromEnum(reg) + @intFromEnum(ptr_reg));
        try ctx.append_u8(0x24);
    } else if (ptr_reg == Register.ebp) {
        try ctx.append_u8(8 * @intFromEnum(reg) + 0x45);
        try ctx.append_u8(0x0);
    } else {
        try ctx.append_u8(8 * @intFromEnum(reg) + @intFromEnum(ptr_reg));
    }
}

pub fn call(ctx: *AssemblerContext, reg: Register) !void {
    try ctx.append_u8(0xFF); // CALL r/m32
    try ctx.append_u8(0xD0 + @intFromEnum(reg));
}

fn jmp(ctx: *AssemblerContext, offset: i32) !void {
    if (offset >= -128 and offset <= 127) {
        try ctx.append_u8(0xEB); // JMP rel8
        try ctx.append_u8(@intCast(offset));
    } else {
        try ctx.append_u8(0xE9); // JMP rel32
        try ctx.append_u32(@intCast(offset));
    }
}

pub const JumpCondition = enum(u8) {
    none,
    equal = 0x74,
    notEqual = 0x75,
};

pub fn jump(ctx: *AssemblerContext, cond: JumpCondition, offset: i32) !void {
    if (cond == JumpCondition.none) {
        try jmp(ctx, offset);
        return;
    }
    if (offset >= -128 and offset <= 127) {
        try ctx.append_u8(@intFromEnum(cond)); // Jcc rel8
        try ctx.append_u8(@intCast(offset));
    } else {
        try ctx.append_u8(0x0F); // Jcc rel32
        try ctx.append_u8(@intFromEnum(cond) + 0x10);
        try ctx.append_u32(@intCast(offset));
    }
}

pub fn add(ctx: *AssemblerContext, reg: Register, value: u8) !void {
    try ctx.append_u8(0x83); // ADD r/m32, imm8
    try ctx.append_u8(0xC0 + @intFromEnum(reg));
    try ctx.append_u8(value);
}

pub fn sub(ctx: *AssemblerContext, reg: Register, value: u8) !void {
    try ctx.append_u8(0x83); // SUB r/m32, imm8
    try ctx.append_u8(0xE8 + @intFromEnum(reg));
    try ctx.append_u8(value);
}

test "x86_codegen" {
    var test_tape = [_]i32{0} ** 10;
    var ctx = AssemblerContext.init(std.testing.allocator, &test_tape[0]);
    defer ctx.binary.deinit(std.testing.allocator);

    try mov_immediate(&ctx, Register.eax, 0x12345678);
    try mov_immediate(&ctx, Register.ebx, 0x9ABCDEF0);

    try mov_from_ptr(&ctx, Register.ecx, Register.esp);
    try mov_to_ptr(&ctx, Register.esp, Register.ecx);

    try add(&ctx, Register.eax, 5);
    try sub(&ctx, Register.ebx, 10);

    try call(&ctx, Register.eax);
    try jump(&ctx, JumpCondition.equal, 0x10);

    const expected = [_]u8{
        0xB8, 0x78, 0x56, 0x34, 0x12, // MOV eax, 0x12345678
        0xBB, 0xF0, 0xDE, 0xBC, 0x9A, // MOV ebx, 0x9ABCDEF0
        0x8B, 0x0C, 0x24, // MOV ecx, [esp]
        0x89, 0x0C, 0x24, // MOV [esp], ecx
        0x83, 0xC0, 0x05, // ADD eax, 5
        0x83, 0xEB, 0x0A, // SUB ebx, 10
        0xFF, 0xD0, // CALL eax
        0x74, 0x10, // JZ offset=16
    };

    try std.testing.expectEqualSlices(u8, &expected, ctx.binary.items);
}
