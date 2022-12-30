const std = @import("std");
const GitRepoStep = @import("GitRepoStep.zig");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const zgl_repo = GitRepoStep.create(b, .{
        .url = "https://github.com/ziglibs/zgl",
        .branch = "master",
        .sha = "bc6a3a086bd4ae7b9fc910d5d0e2e7e2c2e564a1",
    });

    const exe = b.addExecutable("test", "src/main.zig");
    exe.step.dependOn(&zgl_repo.step);
    exe.setTarget(target);
    exe.linkLibC();
    exe.linkSystemLibrary("GL");
    exe.linkSystemLibrary("epoxy");
    exe.linkSystemLibrary("glfw");
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
