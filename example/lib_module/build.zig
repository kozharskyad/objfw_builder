const std = @import("std");
const Build = std.Build;
const ObjFWBuilder = @import("objfw_builder");

pub fn build(b: *Build) {
  const builder = ObjFWBuilder.init(b);

  _ = builder;
}
