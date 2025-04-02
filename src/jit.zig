const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
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

pub fn parseAlloc(allocator: Allocator, code: []const u8) ![]const Token {
    var tokens = ArrayList(Token).init(allocator);
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

pub fn optimizeAlloc(allocator: Allocator, program: []const Token) ![]const Token {
    const cons = try optimizeConsecutiveAdds(allocator, program);
    defer allocator.free(cons);

    const opp = try optimizeOpositeAlloc(allocator, cons);
    defer allocator.free(opp);

    return try allocator.dupe(Token, opp);
}

fn optimizeConsecutiveAdds(allocator: Allocator, program: []const Token) ![]const Token {
    var optimized = ArrayList(Token).init(allocator);
    defer optimized.deinit();

    var i: usize = 0;
    while (i < program.len) : (i += 1) {
        const token = program[i];
        switch (token) {
            .plus => |add| {
                var count: u8 = 1;
                while (i + 1 < program.len and program[i + 1] == .plus) : (i += 1) {
                    count += add;
                }
                try optimized.append(Token{ .plus = count });
            },
            .minus => |subtract| {
                var count: u8 = 1;
                while (i + 1 < program.len and program[i + 1] == .minus) : (i += 1) {
                    count += subtract;
                }
                try optimized.append(Token{ .minus = count });
            },
            .inc => |increment| {
                var count: u8 = 1;
                while (i + 1 < program.len and program[i + 1] == .inc) : (i += 1) {
                    count += increment;
                }
                try optimized.append(Token{ .inc = count });
            },
            .dec => |decrement| {
                var count: u8 = 1;
                while (i + 1 < program.len and program[i + 1] == .dec) : (i += 1) {
                    count += decrement;
                }
                try optimized.append(Token{ .dec = count });
            },
            else => try optimized.append(token),
        }
    }
    return try allocator.dupe(Token, optimized.items);
}

fn optimizeOpositeAlloc(allocator: Allocator, program: []const Token) ![]const Token {
    var optimized = ArrayList(Token).init(allocator);
    defer optimized.deinit();

    var i: usize = 0;
    while (i < program.len) : (i += 1) {
        const token = program[i];
        switch (token) {
            .plus => |add| {
                var subtract: u8 = 0;
                while (i + 1 < program.len and program[i + 1] == .minus) : (i += 1) {
                    subtract += program[i + 1].minus;
                }
                const append = if (add >= subtract)
                    Token{ .plus = add - subtract }
                else
                    Token{ .minus = subtract - add };

                try optimized.append(append);
            },
            .minus => |subtract| {
                var add: u8 = 0;
                while (i + 1 < program.len and program[i + 1] == .plus) : (i += 1) {
                    add += program[i + 1].plus;
                }
                const append = if (subtract >= add)
                    Token{ .minus = subtract - add }
                else
                    Token{ .plus = add - subtract };

                try optimized.append(append);
            },
            .inc => |increment| {
                var decrement: u8 = 0;
                while (i + 1 < program.len and program[i + 1] == .dec) : (i += 1) {
                    decrement += program[i + 1].dec;
                }
                const append = if (increment >= decrement)
                    Token{ .inc = increment - decrement }
                else
                    Token{ .dec = decrement - increment };

                try optimized.append(append);
            },
            .dec => |decrement| {
                var increment: u8 = 0;
                while (i + 1 < program.len and program[i + 1] == .inc) : (i += 1) {
                    increment += program[i + 1].inc;
                }
                const append = if (decrement >= increment)
                    Token{ .dec = decrement - increment }
                else
                    Token{ .inc = increment - decrement };

                try optimized.append(append);
            },
            else => try optimized.append(token),
        }
    }

    return try allocator.dupe(Token, optimized.items);
}

pub fn run(program: []const Token) !void {
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
