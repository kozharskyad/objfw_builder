# objfw_builder
ObjFW projects builder implemented over Zig Build System

## Examples
See [this link](example)

There is three modules:
* main_module - main executable program
* lib_module - basic library
* cat_module - previous library extension by category

To compile example, you must have ObjFW installation, then build can be possible with following command:
```
cd example/main_module # change directory to main module example
OBJFW_ROOT=/path/to/your/objfw zig build # perform build process. OBJFW_ROOT is optional and supports autodetection according objfw-config script
zig-out/bin/main # run main executable
```
