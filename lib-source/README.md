# lib-source

This directory contains source checkouts for third-party libraries that are useful
when rebuilding the native SQLite extensions.

## Submodules

`sqlite-lembed` and `sqlite-vec` are tracked as Git submodules:

```text
lib-source/sqlite-lembed -> https://github.com/landrix/sqlite-lembed.git
lib-source/sqlite-vec    -> https://github.com/landrix/sqlite-vec.git
```

`sqlite-lembed` also contains nested submodules, including `vendor/llama.cpp`.

Initialize or refresh everything from the repository root with:

```powershell
powershell -ExecutionPolicy Bypass -File lib-source/update.ps1
```

To only initialize submodules without pulling a newer `sqlite-lembed` commit:

```powershell
powershell -ExecutionPolicy Bypass -File lib-source/update.ps1 -NoPull
```

For a fresh clone, this is equivalent to:

```powershell
git submodule update --init --recursive
```

## Windows Build Tools

The local machine already has the required core tooling installed:

| Tool | Version / Location |
| --- | --- |
| Git | 2.54.0 |
| Python | 3.13.12 |
| Visual Studio Build Tools 2022 | 17.14.33 |
| MSVC x64 compiler | 19.44.35227 |
| MSBuild | 17.14.40.60911 |
| CMake | 3.31.6-msvc6 |
| Ninja | 1.12.1 |
| winget | 1.28.240 |

`cl`, `cmake`, `ninja`, and `msbuild` are available through the Visual Studio
developer environment, not the default PowerShell `PATH`.

Open a build shell with:

```powershell
cmd /c "call ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"" && powershell"
```

Or run a single build command through the initialized environment:

```powershell
cmd /c "call ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"" && cmake --version"
```

## sqlite-lembed Notes

The bundled `sqlite-lembed` binary used by this Delphi project is maintained in
the `landrix/sqlite-lembed` fork. The current Landrix version is:

```text
v0.0.1-alpha.8-landrix.1
```

It contains the upstream sqlite-lembed pull requests:

- `#19` - update `llama.cpp`, adapt the new llama.cpp API, fix build process.
- `#21` - prevent crashes for long inputs and return better embedding errors.

It also includes Windows CMake fixes and a cleanup fix that releases registered
`llama_context` and `llama_model` instances before shutting down the llama
backend.

## Build and Deploy sqlite-lembed

Build the x64 DLLs and deploy them with:

```powershell
powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-lembed.ps1
```

The script builds from:

```text
lib-source/sqlite-lembed
```

and always copies the runtime DLLs to:

```text
lib/sqlite-lembed/x86_64-win64
```

This directory is the canonical source for the Delphi resource file and release
packaging.

By default the script also copies the same DLLs to the simple Delphi demo output
directory:

```text
examples/simple-delphi/Win64/Debug
```

Use `-SkipDelphiOutput` to update only `lib/sqlite-lembed/x86_64-win64`:

```powershell
powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-lembed.ps1 -SkipDelphiOutput
```

The runtime set is:

```text
lembed0.dll
llama.dll
ggml.dll
ggml-base.dll
ggml-cpu.dll
```

All five files must stay together unless `sqlite-lembed` is rebuilt as a fully
static single DLL.

## Build and Deploy sqlite-vec

`sqlite-vec` builds into one loadable extension file and has no additional
runtime DLL dependencies.

Build the Windows x64 and Windows ARM64 DLLs with:

```powershell
powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-vec.ps1
```

The script copies the outputs to:

```text
lib/sqlite-vec/x86_64-win64/vec0.dll
lib/sqlite-vec/aarch64-win64/vec0.dll
```

To build only one Windows platform:

```powershell
powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-vec.ps1 -Platform x64
powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-vec.ps1 -Platform arm64
```

The Delphi resource file currently embeds the Win64 x64 DLL from:

```text
lib/sqlite-vec/x86_64-win64/vec0.dll
```

## Build Linux sqlite-lembed

Linux binaries are platform-specific. The current WSL environment on this
machine is Linux `aarch64`, so the generated files are ARM64 Linux binaries, not
x86_64 Linux binaries.

Build and deploy the Linux/aarch64 `.so` files with:

```powershell
powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-lembed-wsl.ps1
```

The script builds through WSL and copies the runtime files to:

```text
lib/sqlite-lembed/aarch64-linux
```

The Linux runtime set is:

```text
lembed0.so
libllama.so
libggml.so
libggml-base.so
libggml-cpu.so
```

For x86_64 Linux support, run the same build on an x86_64 Linux/WSL machine or
add a cross-compilation toolchain. Do not ship the `aarch64-linux` binaries as
generic Linux binaries.

On a native x86_64 Linux machine, install the required packages:

```bash
sudo apt update
sudo apt install -y git cmake ninja-build build-essential curl
```

Then run:

```bash
./lib-source/build-sqlite-lembed-linux-x86_64.sh
```

The script copies the runtime files to:

```text
lib/sqlite-lembed/x86_64-linux
```

## Build Linux sqlite-vec

Build and deploy the local WSL Linux/aarch64 `sqlite-vec` binary with:

```powershell
powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-vec-wsl.ps1
```

The script copies the runtime file to:

```text
lib/sqlite-vec/aarch64-linux/vec0.so
```

On a native x86_64 Linux machine, install the required packages:

```bash
sudo apt update
sudo apt install -y git build-essential
```

Then run:

```bash
./lib-source/build-sqlite-vec-linux-x86_64.sh
```

The script copies the runtime file to:

```text
lib/sqlite-vec/x86_64-linux/vec0.so
```

## Model Notes

`all-MiniLM-L6-v2` works as the small demo model with 384 dimensions. BGE-M3
works with the Landrix `sqlite-lembed` build and needs a vector table with 1024
dimensions.

After changing the embedding model or rebuilding against a llama.cpp version
that changes embedding output, regenerate all stored embeddings and rebuild the
vector index.
