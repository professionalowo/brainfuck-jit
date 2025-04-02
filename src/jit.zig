const std = @import("std");

const jit = @This();

var cells = [_]u8{0} ** 65536;

var currentCell: usize = 0;
var programCounter: usize = 0;

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

pub fn parseAlloc(allocator: std.mem.Allocator, code: []const u8) ![]Token {
    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();
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
        if (token) |t| {
            try tokens.append(t);
            i += 1;
        }
    }
    return try allocator.dupe(Token, tokens.items);
}

pub fn run(program: []Token) !void {
    while (programCounter < program.len) : (programCounter += 1) {
        switch (program[programCounter]) {
            .plus => |add| cells[currentCell] +%= add,
            .minus => |subtract| cells[currentCell] -%= subtract,
            .inc => |increment| currentCell +%= increment,
            .dec => |decrement| currentCell -%= decrement,
            .putc => {
                const w = std.io.getStdOut().writer();
                try w.print("{c}", .{cells[currentCell]});
            },
            .getc => cells[currentCell] = try std.io.getStdIn().reader().readByte(),
            .lparen => if (cells[currentCell] == 0) {
                var depth: usize = 1;
                while (depth > 0) {
                    programCounter += 1;
                    switch (program[programCounter]) {
                        .lparen => depth += 1,
                        .rparen => depth -= 1,
                        else => {},
                    }
                }
            },
            .rparen => if (cells[currentCell] != 0) {
                var depth: usize = 1;
                while (depth > 0) {
                    programCounter -= 1;
                    switch (program[programCounter]) {
                        .lparen => depth -= 1,
                        .rparen => depth += 1,
                        else => {},
                    }
                }
            },
        }
    }
}
