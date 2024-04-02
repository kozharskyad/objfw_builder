const std = @import("std");
const Build = std.Build;
const ObjFWBuilder = @import("objfw_builder");

pub fn build(b: *Build) void {
  const builder = ObjFWBuilder.init(b);
  const library = builder.addStaticLibrary("catlib");
  const libmod_dep = b.dependency("lib_module", .{});

  if (libmod_dep.module("include").root_source_file) |libmodIncludePath| {
    library.addIncludePath(libmodIncludePath);
  }

  builder.addObjCSourceFiles(
    library,
    "src",
    &.{ "SomeLib+Eating.m" }
  );

  builder.installArtifact(library);
}
