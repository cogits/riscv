const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("riscv", .{
        .root_source_file = b.path("root.zig"),
        .target = target,
        .optimize = optimize,
    });
}
