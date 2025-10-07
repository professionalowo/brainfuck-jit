const std = @import("std");
const Allocator = std.mem.Allocator;
const t = @import("token");
const Token = t.Token;
const TokenList = t.TokenList;

pub fn parseAlloc(allocator: Allocator, code: []const u8) ![]const Token {
    var tokens = try allocator.alloc(Token, code.len);

    var i: usize = 0;
    for (code) |c| {
        const token: ?Token = switch (c) {
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
        if (token) |tok| {
            tokens[i] = tok;
            i += 1;
        }
    }
    return allocator.realloc(tokens, i);
}
