const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    inline for (.{ "csr", "gpr", "sbi" }) |name| {
        _ = b.addModule(name, .{
            .root_source_file = b.path(name ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });
    }
}
