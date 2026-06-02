# lib-source

This directory contains source checkouts for third-party libraries that are useful
when rebuilding the native SQLite extensions.

## Submodules

`sqlite-lembed` is tracked as a Git submodule:

```text
lib-source/sqlite-lembed -> https://github.com/landrix/sqlite-lembed.git
```

It also contains nested submodules, including `vendor/llama.cpp`.

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

The bundled binary `lembed0.dll` in this Delphi project comes from
`sqlite-lembed v0.0.1-alpha.8`. It can load the small sqlite-lembed example model
`all-MiniLM-L6-v2`, but may fail to load newer GGUF embedding models such as
BGE-M3 with a generic `SQL logic error`.

For BGE-M3 support, rebuild `lembed0.dll` from the `landrix/sqlite-lembed`
submodule with a compatible `llama.cpp` version, then replace the DLL used by
the Delphi example output directory.

After changing the embedding model or rebuilding against a llama.cpp version
that changes embedding output, regenerate all stored embeddings and rebuild the
vector index.
