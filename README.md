# Limine Kotlin Template

This repository will demonstrate how to set up a basic x86-64 kernel in Kotlin/Native + C using Limine.

## Notes

Initialize the `mlibc` submodule and build it once:

```bash
git submodule update --init --recursive
make mlibc
```

Only UEFI is supported in this template.

## Build

**The build system is simplified:**

- Supports kernel build, ISO packaging, and QEMU run
- Assets (Limine and OVMF) are not fetched from the internet

**Available targets:**
- `make` / `make kernel`: Build `build/kernel.elf`
- `make iso`: Build the UEFI ISO image
- `make run`: Run the ISO image in QEMU
- `make clean`: Remove build outputs except `build/mlibc-*`
- `make distclean`: Remove the entire `build` directory
- `make mlibc`: Build bundled `mlibc` into `build/mlibc-x86_64/prefix`

You need to install `konanc`, `cinterop`, `clang`, `clang++`, `ld.lld`, `xorriso`, `make` to build the project, and `qemu-system-x86_64` to boot the ISO.

## License

This project is licensed under the [0BSD License](LICENSE).

It includes binary components from the [Limine project](https://github.com/limine-bootloader/limine), which are licensed under the BSD 2-Clause License.
