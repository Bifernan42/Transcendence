const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/libpong/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const libpong = b.addStaticLibrary(.{
        .name = "libpong",
        .root_module = lib_mod,
    });
    b.installArtifact(libpong);

    const client_mod = b.createModule(.{
        .root_source_file = b.path("src/client/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const client = b.addExecutable(.{
        .name = "client",
        .root_module = client_mod,
    });
    client.linkLibrary(libpong);
    b.installArtifact(client);

    const server_mod = b.createModule(.{
        .root_source_file = b.path("src/server/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Main executable
    const server = b.addExecutable(.{
        .name = "ssps",
        .root_module = server_mod,
    });
    server.linkLibrary(libpong);
    b.installArtifact(server);

    const run_cmd = b.addRunArtifact(server);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = server_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    const check_server = b.addExecutable(.{
        .name = "ssps",
        .root_module = server_mod,
    });

    const check_step = b.step("check", "Check the compilation");
    check_step.dependOn(&check_server.step);
}
