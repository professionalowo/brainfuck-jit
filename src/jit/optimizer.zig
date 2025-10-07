const std = @import("std");
const Allocator = std.mem.Allocator;
const t = @import("token");
const Token = t.Token;
const TokenList = t.TokenList;

pub fn optimizeAlloc(allocator: Allocator, program: []const Token) ![]const Token {
    const cons = try optimizeConsecutiveAdds(allocator, program);
    defer allocator.free(cons);

    const opp = try optimizeOppositeAlloc(allocator, cons);
    return opp;
}

fn optimizeConsecutiveAdds(allocator: Allocator, program: []const Token) ![]const Token {
    var optimized = TokenList.init(allocator);

    var i: usize = 0;
    while (i < program.len) : (i += 1) {
        const token = program[i];
        switch (token) {
            .plus => |add| {
                var count: u8 = 1;
                while (i + 1 < program.len and program[i + 1] == .plus) : (i += 1) {
                    count += add;
                }
                try optimized.append(.{ .plus = count });
            },
            .minus => |subtract| {
                var count: u8 = 1;
                while (i + 1 < program.len and program[i + 1] == .minus) : (i += 1) {
                    count += subtract;
                }
                try optimized.append(.{ .minus = count });
            },
            .inc => |increment| {
                var count: u8 = 1;
                while (i + 1 < program.len and program[i + 1] == .inc) : (i += 1) {
                    count += increment;
                }
                try optimized.append(.{ .inc = count });
            },
            .dec => |decrement| {
                var count: u8 = 1;
                while (i + 1 < program.len and program[i + 1] == .dec) : (i += 1) {
                    count += decrement;
                }
                try optimized.append(.{ .dec = count });
            },
            else => try optimized.append(token),
        }
    }
    return try optimized.toOwnedSlice();
}

fn optimizeOppositeAlloc(allocator: Allocator, program: []const Token) ![]const Token {
    var optimized = TokenList.init(allocator);

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

    return try optimized.toOwnedSlice();
}
