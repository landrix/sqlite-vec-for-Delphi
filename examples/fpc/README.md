# FPC Linux Examples

## LembedVectorDemo

`LembedVectorDemo.lpr` is a Linux/FPC console version of the simple Delphi
document search demo. It uses `vec0 + lembed` and defaults to BGE-M3:

```text
bge-m3-q8_0.gguf
model name: bge-m3
dimensions: 1024
```

Build in WSL:

```bash
./examples/fpc/build-lembed-vector-demo.sh
```

Run in WSL:

```bash
./examples/fpc/run-lembed-vector-demo.sh
```

## VectorLembedDemo

`VectorLembedDemo.lpr` is a Linux/FPC console version of the Delphi product
search demo. It intentionally uses only `vec0 + lembed` and does not require
`sqlite-vector`.

Build in WSL:

```bash
./examples/fpc/build-vector-lembed-demo.sh
```

Run in WSL:

```bash
./examples/fpc/run-vector-lembed-demo.sh
```

Required runtime files:

```text
lib/sqlite-lembed/aarch64-linux/lembed0.so
lib/sqlite-lembed/aarch64-linux/libllama.so
lib/sqlite-lembed/aarch64-linux/libggml.so
lib/sqlite-lembed/aarch64-linux/libggml-base.so
lib/sqlite-lembed/aarch64-linux/libggml-cpu.so
lib/sqlite-vec/aarch64-linux/vec0.so
```

Build them from Windows with:

```powershell
powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-lembed-wsl.ps1
powershell -ExecutionPolicy Bypass -File lib-source/build-sqlite-vec-wsl.ps1
```

Place the demo models in `examples/fpc` or the repository root:

```text
bge-m3-q8_0.gguf
all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
```
