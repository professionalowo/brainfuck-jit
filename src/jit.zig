const std = @import("std");
const t = @import("token");
const Token = t.Token;

pub const parser = @import("parser");
pub const optimizer = @import("optimizer");

var cells = [_]u8{0} ** 65536;
var currentCell: usize = 0;
var programCounter: usize = 0;

pub fn run(program: []const Token) !void {
    var w = std.fs.File.stdout().writer(&.{});
    const stdout = &w.interface;
    var r = std.fs.File.stdin().reader(&.{});
    const stdin = &r.interface;
    while (programCounter < program.len) : (programCounter += 1) {
        switch (program[programCounter]) {
            .plus => |add| cells[currentCell] +%= add,
            .minus => |subtract| cells[currentCell] -%= subtract,
            .inc => |increment| currentCell +%= increment,
            .dec => |decrement| currentCell -%= decrement,
            .putc => try stdout.print("{c}", .{cells[currentCell]}),
            .getc => cells[currentCell] = try stdin.takeByte(),
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
    try stdout.flush();
}
