const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");

const neighborOffsets = [_][2]i32{
    .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 },
    .{ -1, 0 },  .{ 1, 0 },  .{ -1, 1 },
    .{ 0, 1 },   .{ 1, 1 },
};
const screenWidth = 800;
const screenHeight = 450;
const gridColor: rl.Color = .black;
const numVerticalGridLines = 10;
const numHorizontalGridLines = 8;
const verticalSpacing = screenWidth / numVerticalGridLines;
const horizontalSpacing = screenHeight / numHorizontalGridLines;

pub fn main(init: std.process.Init) !void {
    rl.initWindow(screenWidth, screenHeight, "Game of Life");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var state: std.AutoHashMap(Cell, bool) = .init(init.gpa);
    defer state.deinit();
    var nextState: std.AutoHashMap(Cell, bool) = .init(init.gpa);
    defer nextState.deinit();

    var swap = false;

    var cam = rl.Camera2D{
        .offset = .{ .x = 0, .y = 0 },
        .target = .{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    while (!rl.windowShouldClose()) {
        const effectiveState = if (swap) &nextState else &state;
        const scroll = rl.getMouseWheelMove();

        if (scroll > 0) {
            cam.zoom *= 1.1;
        } else if (scroll < 0) {
            cam.zoom *= 0.9;
        }

        if (rl.isKeyPressed(.space)) {
            try stepState(&state, &nextState, &swap);
        }

        if (rl.isMouseButtonPressed(.left)) {
            const mousePos = rl.getMousePosition();
            const cell = getMousePosToCell(mousePos, cam);
            try birthCell(cell, effectiveState);
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.beginMode2D(cam);
        drawGrid(cam);
        drawState(effectiveState);
        rl.endMode2D();
    }
}

fn drawGrid(cam: rl.Camera2D) void {
    const edge = rl.getScreenToWorld2D(.{ .x = screenWidth, .y = screenHeight }, cam);
    const width: i32 = @intFromFloat(edge.x);
    const height: i32 = @intFromFloat(edge.y);
    const numVerticalLines: usize = @intCast(@divTrunc(width, verticalSpacing) + 1);
    const numHorizontalLines: usize = @intCast(@divTrunc(height, horizontalSpacing) + 1);

    for (0..numVerticalLines) |i| {
        const spacing = @as(i32, @intCast(i)) * verticalSpacing;
        rl.drawLine(spacing, 0, spacing, height, gridColor);
    }

    for (0..numHorizontalLines) |i| {
        const spacing = @as(i32, @intCast(i)) * horizontalSpacing;
        rl.drawLine(0, spacing, width, spacing, gridColor);
    }
}

fn getMousePosToCell(pos: rl.Vector2, cam: rl.Camera2D) Cell {
    const worldPos = rl.getScreenToWorld2D(pos, cam);
    const x = @divTrunc(@as(i32, @intFromFloat(worldPos.x)), verticalSpacing);
    const y = @divTrunc(@as(i32, @intFromFloat(worldPos.y)), horizontalSpacing);

    return Cell{ .x = x, .y = y };
}

const Cell = struct { x: i32, y: i32 };

fn drawCell(cell: Cell) void {
    rl.drawRectangle(cell.x * verticalSpacing, cell.y * horizontalSpacing, verticalSpacing, horizontalSpacing, gridColor);
}

fn drawState(state: *const std.AutoHashMap(Cell, bool)) void {
    var iterator = state.iterator();

    while (iterator.next()) |entry| {
        const cell = entry.key_ptr.*;
        const isAlive = entry.value_ptr.*;
        if (isAlive) {
            drawCell(cell);
        }
    }
}

fn stepState(state: *std.AutoHashMap(Cell, bool), nextState: *std.AutoHashMap(Cell, bool), swap: *bool) !void {
    const effectiveState = if (swap.*) nextState else state;
    const ineffectiveState = if (swap.*) state else nextState;
    var iterator = effectiveState.iterator();

    while (iterator.next()) |entry| {
        const cell = entry.key_ptr.*;
        const liveNeighborCount = countLiveNeighbors(cell, effectiveState);

        if (isCellAlive(cell, effectiveState) and (liveNeighborCount == 2 or liveNeighborCount == 3)) {
            try birthCell(cell, ineffectiveState);
        }

        for (neighborOffsets) |offset| {
            const x = cell.x + offset[0];
            const y = cell.y + offset[1];
            const neighbor = Cell{ .x = x, .y = y };

            if (isCellDead(neighbor, effectiveState)) {
                const neighborLiveNeighborCount = countLiveNeighbors(neighbor, effectiveState);
                if (neighborLiveNeighborCount == 3) {
                    try birthCell(neighbor, ineffectiveState);
                }
            }
        }
    }

    swap.* = !swap.*;
    killAllCells(effectiveState);
}

fn countLiveNeighbors(cell: Cell, state: *const std.AutoHashMap(Cell, bool)) usize {
    var count: usize = 0;

    for (neighborOffsets) |offset| {
        const x = cell.x + offset[0];
        const y = cell.y + offset[1];
        const neighbor = Cell{ .x = x, .y = y };
        count += if (isCellAlive(neighbor, state)) 1 else 0;
    }

    return count;
}

fn isCellAlive(cell: Cell, state: *const std.AutoHashMap(Cell, bool)) bool {
    if (state.get(cell)) |isAlive| {
        return isAlive;
    } else {
        return false;
    }
}

fn isCellDead(cell: Cell, state: *const std.AutoHashMap(Cell, bool)) bool {
    return !isCellAlive(cell, state);
}

fn birthCell(cell: Cell, state: *std.AutoHashMap(Cell, bool)) !void {
    if (state.getEntry(cell)) |entry| {
        entry.value_ptr.* = true;
    } else {
        try state.put(cell, true);
    }
}

fn killCell(cell: Cell, state: *std.AutoHashMap(Cell, bool)) void {
    if (state.getEntry(cell)) |entry| {
        entry.value_ptr.* = false;
    }
}

fn killAllCells(state: *std.AutoHashMap(Cell, bool)) void {
    var iterator = state.iterator();

    while (iterator.next()) |entry| {
        entry.value_ptr.* = false;
    }
}
