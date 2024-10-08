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

fn populateDependencies(
  self: *const Self,
  artifact: *Build.Step.Compile,
  without_system_libs: bool
) void {
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

fn detect_objfw_root(b: *Build) ?[]const u8 {
  const cwd = std.fs.cwd();

  var env = std.process.getEnvMap(b.allocator)
    catch @panic("Unable to read environment variables");

  defer env.deinit();

  if (env.get("OBJFW_ROOT")) |objfw_path| {
    if (cwd.statFile(objfw_path)) |_| {
      return b.dupe(objfw_path);
    } else |_| {}
  }

  if (b.findProgram(&.{ "objfw-config" }, &.{})) |script_path| {
    const file = std.fs.openFileAbsolute(
      script_path,
      .{}
    ) catch @panic("Cannot open objfw-config script");

    defer file.close();

    const file_reader = file.reader();
    var prefix_line: ?[]const u8 = null;

    while (file_reader.readUntilDelimiterAlloc(b.allocator, '\n', 256)) |line| {
      if (std.mem.startsWith(u8, line, "prefix=\"")) {
        prefix_line = line;
        break;
      }
    } else |_| {}

    if (prefix_line) |l| {
      var it = std.mem.split(u8, l, "\"");

      if (it.next()) |var_name| {
        if (std.mem.eql(u8, var_name, "prefix=")) {
          if (it.next()) |objfw_path| {
            if (cwd.statFile(objfw_path)) |_| {
              return b.dupe(objfw_path);
            } else |_| {}
          }
        }
      }
    }
  } else |_| {}

  return null;
}

pub fn init(builder: *Build) Self {
  var env = std.process.getEnvMap(builder.allocator)
    catch @panic("Unable to read environment variables");

  defer env.deinit();

  const root = detect_objfw_root(builder) orelse
    @panic("ObjFW root not set (OBJFW_ROOT=/path/to/objfw zig build)");

  const include_path: Build.LazyPath = .{
    .src_path = .{
      .owner = builder,
      .sub_path = builder.pathFromRoot(builder.pathJoin(&.{ "src", "include" }))
    }
  };

  _ = builder.addModule(
    "include",
    .{ .root_source_file = include_path }
  );

  return Self {
    .base = builder,
    .root = root,
    .objfw_include_path = .{
      .src_path = .{
        .owner = builder,
        .sub_path = builder.pathJoin(&.{ root, "include" })
      }
    },
    .objfw_library_path = .{
      .src_path = .{
        .owner = builder,
        .sub_path = builder.pathJoin(&.{ root, "lib" }),
      }
    },
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

pub fn addStaticLibrary(
  self: *const Self,
  name: []const u8
) *Build.Step.Compile {
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
  artifact.addCSourceFiles(.{
    .root = .{
      .src_path = .{
        .owner = self.base,
        .sub_path = root_path,
      }
    },
    .files = files,
    .flags = default_compiler_flags
  });
}

pub fn dependency(self: *const Self, name: []const u8) *Build.Dependency {
  return self.base.dependency(name, .{});
}

pub fn installArtifact(self: *const Self, artifact: *Build.Step.Compile) void {
  self.base.installArtifact(artifact);
}

pub fn build(_: *Build) void {}
