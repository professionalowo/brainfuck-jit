const std = @import("std");
pub const TokenList = std.ArrayList(Token);

pub const Token = union(enum) {
    inc: u8,
    dec: u8,

    plus: u8,
    minus: u8,

    putc,
    getc,

    lparen,
    rparen,
};
