### Run hello world sample with emscripten

$EMSCRIPTEN_ROOT/emcc tests/hello_world.c
node a.out.js
$EMSCRIPTEN_ROOT/emcc tests/hello_world.c -o hello.html


### Configure repo to work with
1. Build Urho3D with Lua scripting support -DURHO3D_LUA=1
https://urho3d.github.io/documentation/1.7/_building.html

2. Move Autoload, CoreData, Data directories with files and Urho3DPlayer to repository root

3. Move samples directory to repository root

4. Check if ./Urho3DPlayer samples/01_HelloWorld.lua works

### Install required dependencies with luarocks
luarocks install debugger
