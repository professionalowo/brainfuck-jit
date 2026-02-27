const std = @import("std");
const Token = @import("frontend").Token;

var cells = [_]u8{0} ** 65536;
var currentCell: usize = 0;
var programCounter: usize = 0;

pub fn run(program: []const Token, writer: *std.Io.Writer, reader: *std.Io.Reader) !void {
    while (programCounter < program.len) : (programCounter += 1) {
        switch (program[programCounter]) {
            .plus => |add| cells[currentCell] +%= add,
            .minus => |subtract| cells[currentCell] -%= subtract,
            .inc => |increment| currentCell +%= increment,
            .dec => |decrement| currentCell -%= decrement,
            .putc => try writer.print("{c}", .{cells[currentCell]}),
            .getc => cells[currentCell] = try reader.takeByte(),
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
    try writer.flush();
}
