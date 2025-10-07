const std = @import("std");
const Allocator = std.mem.Allocator;
const Token = @import("token").Token;

pub fn parseAlloc(allocator: Allocator, code: []const u8) ![]const Token {
    var tokens = try allocator.alloc(Token, code.len);

    var i: usize = 0;
    for (code) |c| {
        if (charToToken(c)) |tok| {
            tokens[i] = tok;
            i += 1;
        }
    }
    return tokens[0..i];
}

fn charToToken(char: u8) ?Token {
    return switch (char) {
        '+' => .{ .plus = 1 },
        '-' => .{ .minus = 1 },
        '>' => .{ .inc = 1 },
        '<' => .{ .dec = 1 },
        '.' => .putc,
        ',' => .getc,
        '[' => .lparen,
        ']' => .rparen,
        else => null,
    };
}
