# Limine Kotlin Template

This repository will demonstrate how to set up a basic x86-64 kernel in Kotlin using Limine.

## Notes

Initialize the `mlibc` submodule:

```bash
git submodule update --init --recursive
```

Only UEFI is supported in this template.

## Build

This project uses Gradle for kernel build, ISO packaging, and QEMU run.

- Supports kernel build, ISO packaging, and QEMU run
- Cross-platform compatible (Linux/macOS/Windows)

**Available Gradle tasks:**
- `./gradlew build`: Build kernel ELF
- `./gradlew buildIso`: Build the UEFI ISO image
- `./gradlew run`: Run the ISO image in QEMU
- `./gradlew clean`: Clean kernel build outputs
- `./gradlew cleanAll`: Remove entire build directory
- `./gradlew buildMlibc`: Build bundled mlibc

You need to install:
- JDK (Java Development Kit)
- Clang (`clang`, `clang++`)
- LLD (`ld.lld`)
- `xorriso` (for ISO creation)
- `qemu-system-x86_64` (for emulation)

## License

This project is licensed under the [0BSD License](LICENSE).

It includes binary components from the [Limine project](https://github.com/limine-bootloader/limine), which are licensed under the BSD 2-Clause License.
