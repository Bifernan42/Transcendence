const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib");

    // Modules - Lib, Server, Client
    const libpong_module = b.createModule(.{
        .root_source_file = b.path("lib/root.zig"),
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });
    libpong_module.addImport("raylib", raylib);
    libpong_module.addImport("raygui", raygui);
    libpong_module.linkLibrary(raylib_artifact);

    const server_module = b.createModule(.{
        .root_source_file = b.path("server/main.zig"),
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });
    server_module.addImport("libpong", libpong_module);

    const client_module = b.createModule(.{
        .root_source_file = b.path("client/main.zig"),
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });
    client_module.addImport("libpong", libpong_module);

    // Artifacts - Lib, Server, Client
    const lib = b.addSharedLibrary(.{
        .name = "pong",
        .root_module = libpong_module,
    });
    b.installArtifact(lib);

    const server = b.addExecutable(.{
        .name = "server",
        .root_module = server_module,
        .linkage = .dynamic,
    });
    b.installArtifact(server);

    const client = b.addExecutable(.{
        .name = "client",
        .root_module = client_module,
        .linkage = .dynamic,
    });
    b.installArtifact(client);

    // Check Step - Lib, Server, Client
    const check_lib = b.addSharedLibrary(.{
        .name = "pong",
        .root_module = libpong_module,
    });

    const check_server = b.addExecutable(.{
        .name = "server",
        .root_module = server_module,
    });

    const check_client = b.addExecutable(.{
        .name = "client",
        .root_module = client_module,
    });

    const check_step = b.step("check", "run compilation without emitting binaries");
    check_step.dependOn(&check_lib.step);
    check_step.dependOn(&check_server.step);
    check_step.dependOn(&check_client.step);

    // Run Step - Server, Client
    const run_step = b.step("run", "Run the server and the client");
    const run_server = b.addRunArtifact(server);
    const run_client = b.addRunArtifact(client);

    run_client.step.dependOn(&run_server.step);
    run_step.dependOn(&run_client.step);

    // Test Step - Lib, Server, Client
    const test_lib = b.addTest(.{
        .root_module = libpong_module,
    });

    const test_server = b.addTest(.{
        .root_module = server_module,
    });

    const test_client = b.addTest(.{
        .root_module = client_module,
    });

    const run_test_lib = b.addRunArtifact(test_lib);
    const run_test_server = b.addRunArtifact(test_server);
    const run_test_client = b.addRunArtifact(test_client);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_test_lib.step);
    test_step.dependOn(&run_test_server.step);
    test_step.dependOn(&run_test_client.step);
}
