const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Modules - Lib, Server, Client
    const libpong_module = b.createModule(.{
        .root_source_file = b.path("lib/root.zig"),
        .optimize = optimize,
        .target = target,
    });

    const server_module = b.createModule(.{
        .root_source_file = b.path("server/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    server_module.addImport("libpong", libpong_module);

    const client_module = b.createModule(.{
        .root_source_file = b.path("client/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    client_module.addImport("libpong", libpong_module);

    // Artifacts - Lib, Server, Client
    const lib = b.addStaticLibrary(.{
        .name = "libpong",
        .root_module = libpong_module,
    });
    b.installArtifact(lib);

    const server = b.addExecutable(.{
        .name = "server",
        .root_module = server_module,
    });
    b.installArtifact(server);

    const client = b.addExecutable(.{
        .name = "client",
        .root_module = client_module,
    });
    b.installArtifact(client);

    // Check Step - Lib, Server, Client
    const check_lib = b.addStaticLibrary(.{
        .name = "libpong",
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

    const run_step = b.step("run", "Run the server and the client");
    const run_server = b.addRunArtifact(server);
    const run_client = b.addRunArtifact(client);

    run_client.step.dependOn(&run_server.step);
    run_step.dependOn(&run_client.step);
}
