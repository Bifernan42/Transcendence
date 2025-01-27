const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/libpong/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const client_mod = b.createModule(.{
        .root_source_file = b.path("src/client/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    client_mod.addImport("libpong", lib_mod);

    const server_mod = b.createModule(.{
        .root_source_file = b.path("src/server/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    server_mod.addImport("libpong", lib_mod);

    const libpong = b.addStaticLibrary(.{
        .name = "libpong",
        .root_module = lib_mod,
    });
    b.installArtifact(libpong);

    const client = b.addExecutable(.{
        .name = "client",
        .root_module = client_mod,
    });
    client.linkLibrary(libpong);
    b.installArtifact(client);

    const server = b.addExecutable(.{
        .name = "server",
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
        .name = "server",
        .root_module = server_mod,
    });

    const check_client = b.addExecutable(.{
        .name = "client",
        .root_module = client_mod,
    });

    const check_lib = b.addStaticLibrary(.{
        .name = "libpong",
        .root_module = lib_mod,
    });

    const check_step = b.step("check", "Check the compilation");
    check_step.dependOn(&check_server.step);
    check_step.dependOn(&check_client.step);
    check_step.dependOn(&check_lib.step);
}
