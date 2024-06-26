const std = @import("std");
const Build = std.Build;
const ObjFWBuilder = @import("objfw_builder");

pub fn build(b: *Build) void {
  const builder = ObjFWBuilder.init(b);
  const library = builder.addStaticLibrary("rootlib");

  builder.addObjCSourceFiles(
    library,
    "src",
    &.{ "SomeLib.m" }
  );

  builder.installArtifact(library);
}
