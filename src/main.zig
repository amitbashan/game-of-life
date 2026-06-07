const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");

const screenWidth = 800;
const screenHeight = 450;
const gridColor: rl.Color = .black;
const numVerticalGridLines = 10;
const numHorizontalGridLines = 5;

pub fn main(_: std.process.Init) !void {
    rl.initWindow(screenWidth, screenHeight, "Game of Life");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var cam = rl.Camera2D{
        .offset = .{ .x = 0, .y = 0 },
        .target = .{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    while (!rl.windowShouldClose()) {
        const scroll = rl.getMouseWheelMove();

        if (scroll > 0) {
            cam.zoom *= 1.1;
        } else if (scroll < 0) {
            cam.zoom *= 0.9;
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.beginMode2D(cam);
        drawGrid(cam);
        rl.endMode2D();
    }
}

fn drawGrid(cam: rl.Camera2D) void {
    const edge = rl.getScreenToWorld2D(.{ .x = screenWidth, .y = screenHeight }, cam);
    const width: i32 = @intFromFloat(edge.x);
    const height: i32 = @intFromFloat(edge.y);
    const verticalSpacing = screenWidth / numVerticalGridLines;
    const horizontalSpacing = screenHeight / numHorizontalGridLines;
    const numVerticalLines: usize = @intCast(@divTrunc(width, verticalSpacing));
    const numHorizontalLines: usize = @intCast(@divTrunc(height, horizontalSpacing));

    for (0..numVerticalLines) |i| {
        const spacing = @as(i32, @intCast(i)) * verticalSpacing;
        rl.drawLine(spacing, 0, spacing, height, gridColor);
    }

    for (0..numHorizontalLines) |i| {
        const spacing = @as(i32, @intCast(i)) * horizontalSpacing;
        rl.drawLine(0, spacing, width, spacing, gridColor);
    }
}
