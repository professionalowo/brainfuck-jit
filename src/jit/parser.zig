const std = @import("std");
const Allocator = std.mem.Allocator;
const t = @import("token");
const Token = t.Token;
const TokenList = t.TokenList;

pub fn parseAlloc(allocator: Allocator, code: []const u8) ![]const Token {
    var tokens = try TokenList.initCapacity(allocator, code.len);
    var i: usize = 0;
    for (code) |c| {
        const token: ?Token = switch (c) {
            '+' => Token{ .plus = 1 },
            '-' => Token{ .minus = 1 },
            '>' => Token{ .inc = 1 },
            '<' => Token{ .dec = 1 },
            '.' => .putc,
            ',' => .getc,
            '[' => .lparen,
            ']' => .rparen,
            else => null,
        };
        if (token) |tok| {
            try tokens.append(tok);
            i += 1;
        }
    }
    return try tokens.toOwnedSlice();
}
