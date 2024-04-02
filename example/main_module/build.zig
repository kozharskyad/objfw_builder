const std = @import("std");
const Build = std.Build;
const ObjFWBuilder = @import("objfw_builder");

pub fn build(b: *Build) void {
  const builder = ObjFWBuilder.init(b);
  const executable = builder.addExecutable("main");
  const libmod_dep = b.dependency("lib_module", .{});
  const catmod_dep = b.dependency("cat_module", .{});

  if (libmod_dep.module("include").root_source_file) |libmodIncludePath| {
    executable.addIncludePath(libmodIncludePath);
  }

  if (catmod_dep.module("include").root_source_file) |catmodIncludePath| {
    executable.addIncludePath(catmodIncludePath);
  }

  builder.addObjCSourceFiles(
    executable,
    "src",
    &.{ "Application.m", "main.m" }
  );

  executable.linkLibrary(libmod_dep.artifact("rootlib"));
  executable.linkLibrary(catmod_dep.artifact("catlib"));

  builder.installArtifact(executable);
}
