const std = @import("std");
const Build = std.Build;

base: *Build,
root: []const u8,
objfw_include_path: Build.LazyPath,
objfw_library_path: Build.LazyPath,
include_path: Build.LazyPath,
target: Build.ResolvedTarget,
optimize: std.builtin.OptimizeMode,

const Self = @This();

const default_link_options: Build.Module.LinkSystemLibraryOptions = .{
  .preferred_link_mode = .static
};

const default_compiler_flags = &.{
  "-fexceptions",
  "-fobjc-exceptions",
  "-funwind-tables",
  "-fconstant-string-class=OFConstantString",
  "-Xclang",
  "-fno-constant-cfstrings",
  "-Xclang",
  "-fblocks",
  "-Wall",
  "-fobjc-arc",
  "-fobjc-arc-exceptions"
};

fn populateDependencies(self: *const Self, artifact: *Build.Step.Compile, without_system_libs: bool) void {
  artifact.force_load_objc = true;

  artifact.addIncludePath(self.objfw_include_path);
  artifact.addIncludePath(self.include_path);
  artifact.addLibraryPath(self.objfw_library_path);

  if (!without_system_libs) {
    artifact.linkSystemLibrary2("m", default_link_options);
    artifact.linkSystemLibrary2("dl", default_link_options);
    artifact.linkSystemLibrary2("objc", default_link_options);
    artifact.linkSystemLibrary2("objfw", default_link_options);
    artifact.linkSystemLibrary2("pthread", default_link_options);
  }
}

pub fn init(builder: *Build) Self {
  const root = builder.option(
    []const u8, "objfw-root",
    "ObjFW root path"
  ) orelse "/opt/homebrew/Cellar/objfw/HEAD-1973886";

  const include_path: Build.LazyPath = .{
    .path = builder.pathFromRoot("src/include")
  };

  _ = builder.addModule(
    "include",
    .{ .root_source_file = include_path }
  );

  return Self {
    .base = builder,
    .root = root,
    .objfw_include_path = .{ .path = builder.pathJoin(&.{ root, "include" }) },
    .objfw_library_path = .{ .path = builder.pathJoin(&.{ root, "lib" }) },
    .include_path = include_path,
    .target = builder.standardTargetOptions(.{}),
    .optimize = builder.standardOptimizeOption(.{}),
  };
}

pub fn addExecutable(self: *const Self, name: []const u8) *Build.Step.Compile {
  const executable = self.base.addExecutable(.{
    .name = name,
    .target = self.target,
    .optimize = self.optimize,
  });

  self.populateDependencies(executable, false);

  return executable;
}

pub fn addStaticLibrary(self: *const Self, name: []const u8) *Build.Step.Compile {
  const library = self.base.addStaticLibrary(.{
    .name = name,
    .target = self.target,
    .optimize = self.optimize,
  });

  self.populateDependencies(library, true);

  return library;
}

pub fn addObjCSourceFiles(
  self: *const Self,
  artifact: *Build.Step.Compile,
  root_path: []const u8,
  files: []const []const u8
) void {
  _ = self;

  artifact.addCSourceFiles(.{
    .root = .{ .path = root_path },
    .files = files,
    .flags = default_compiler_flags
  });
}

pub fn installArtifact(self: *const Self, artifact: *Build.Step.Compile) void {
  self.base.installArtifact(artifact);
}

pub fn build(_: *Build) void {}
