PROJECT_NAME := template
BUILD_DIR := build
ISO_DIR := $(BUILD_DIR)/iso

KONANC ?= konanc
CINTEROP ?= cinterop
CROSS_CC ?= clang
CROSS_CXX ?= clang++
LINKER ?= ld.lld
XORRISO ?= xorriso
QEMU ?= qemu-system-x86_64

KOTLIN_SRC := kernel/kotlin/kernel.kt
LIMINE_DEF := kernel/c/limine.def
BOOT_SRC := kernel/c/boot.c
SHIM_SRC := kernel/c/shim.c
LINKER_SCRIPT := assets/linker.ld
KONAN_TOOLROOT ?= $(HOME)/.konan/dependencies/x86_64-unknown-linux-gnu-gcc-8.3.0-glibc-2.19-kernel-4.9-2
KONAN_GCC_LIBDIR := $(KONAN_TOOLROOT)/lib/gcc/x86_64-unknown-linux-gnu/8.3.0
KONAN_SYSROOT_LIBDIR := $(KONAN_TOOLROOT)/x86_64-unknown-linux-gnu/sysroot/lib
MLIBC_PREFIX ?= build/mlibc-x86_64/prefix
MLIBC_LIBDIR := $(MLIBC_PREFIX)/lib
LIBGCC_A := $(KONAN_GCC_LIBDIR)/libgcc.a
LIBGCC_EH_A := $(KONAN_GCC_LIBDIR)/libgcc_eh.a
LIBSTDCXX_A := $(KONAN_SYSROOT_LIBDIR)/libstdc++.a
MLIBC_LIBC_A := $(MLIBC_LIBDIR)/libc.a
MLIBC_LIBM_A := $(MLIBC_LIBDIR)/libm.a
MLIBC_PTHREAD_A := $(MLIBC_LIBDIR)/libpthread.a
MLIBC_RUNTIME_LIBS := $(MLIBC_LIBC_A) $(MLIBC_LIBM_A) $(MLIBC_PTHREAD_A)
MLIBC_STAMP := $(dir $(MLIBC_PREFIX)).built

KOTLIN_LIB := $(BUILD_DIR)/libkernel.a
LIMINE_KLIB := $(BUILD_DIR)/limine.klib
BOOT_OBJ := $(BUILD_DIR)/boot.o
SHIM_OBJ := $(BUILD_DIR)/shim.o
C_OBJS := $(BOOT_OBJ) $(SHIM_OBJ)
KERNEL_ELF := $(BUILD_DIR)/kernel.elf
ISO_IMAGE := $(BUILD_DIR)/$(PROJECT_NAME).iso
KONAN_RUNTIME_LIBS := $(MLIBC_RUNTIME_LIBS) $(LIBSTDCXX_A) $(LIBGCC_A) $(LIBGCC_EH_A)
KONAN_RUNTIME_LDFLAGS := --start-group $(KONAN_RUNTIME_LIBS) --end-group
CLEAN_FILES = $(filter-out $(wildcard $(BUILD_DIR)/mlibc-*),$(wildcard $(BUILD_DIR)/*))

CFLAGS := -target x86_64-freestanding
CFLAGS += -std=c23 -ffreestanding -nostdinc -fno-builtin
CFLAGS += -m64 -mno-red-zone -mcmodel=kernel -fno-stack-protector
CFLAGS += -mno-80387 -mno-mmx -mno-sse -mno-sse2
CFLAGS += -Wall -Wextra -Wpedantic -Werror
CFLAGS += -Ikernel/c -O2

LDFLAGS := -m elf_x86_64
LDFLAGS += -nostdlib
LDFLAGS += -z max-page-size=0x1000
LDFLAGS += --gc-sections
LDFLAGS += -T $(LINKER_SCRIPT)

XORRISOFLAGS = -as mkisofs --efi-boot limine/limine-uefi-cd.bin -efi-boot-part --efi-boot-image
QEMUFLAGS = -m 256m -M q35 -cpu qemu64,+x2apic -no-reboot
QEMUFLAGS += -drive if=pflash,format=raw,readonly=on,file=assets/ovmf-code.fd

MLIBC_CC := $(CROSS_CC) -target x86_64-unknown-none
MLIBC_CXX := $(CROSS_CXX) -target x86_64-unknown-none
MLIBC_CFLAGS := -g -O2 -pipe
MLIBC_CFLAGS += -Wall -Wextra -nostdinc -ffreestanding
MLIBC_CFLAGS += -fno-stack-protector -fno-stack-check -fno-lto -fno-PIC
MLIBC_CFLAGS += -ffunction-sections -fdata-sections
MLIBC_CFLAGS += -m64 -march=x86-64 -mno-red-zone -mcmodel=kernel
MLIBC_CFLAGS += -D__thread='' -D_Thread_local='' -D_GNU_SOURCE
MLIBC_CXXFLAGS := $(MLIBC_CFLAGS) -fno-rtti -fno-exceptions -fno-sized-deallocation

.PHONY: all kernel iso run clean distclean mlibc

all: kernel

kernel: $(KERNEL_ELF)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(LIMINE_KLIB): $(LIMINE_DEF) kernel/c/limine.h kernel/c/bridge.h | $(BUILD_DIR)
	$(CINTEROP) -def $(LIMINE_DEF) -o $(BUILD_DIR)/limine

$(KOTLIN_LIB): $(KOTLIN_SRC) $(LIMINE_KLIB) | $(BUILD_DIR)
	$(KONANC) $(KOTLIN_SRC) -library $(LIMINE_KLIB) -produce static -nostdlib -nomain -o $(BUILD_DIR)/kernel

$(BOOT_OBJ): $(BOOT_SRC) kernel/c/limine.h | $(BUILD_DIR)
	$(CROSS_CC) $(CFLAGS) -c $< -o $@

$(SHIM_OBJ): $(SHIM_SRC) | $(BUILD_DIR)
	$(CROSS_CC) $(CFLAGS) -c $< -o $@

$(KERNEL_ELF): $(C_OBJS) $(KOTLIN_LIB) $(LINKER_SCRIPT) $(KONAN_RUNTIME_LIBS)
	$(LINKER) $(LDFLAGS) -o $@ $(C_OBJS) $(KOTLIN_LIB) $(KONAN_RUNTIME_LDFLAGS)

iso: $(ISO_IMAGE)

$(ISO_IMAGE): $(KERNEL_ELF)
	rm -rf $(ISO_DIR)
	mkdir -p $(ISO_DIR)/limine
	cp assets/limine/limine.conf $(ISO_DIR)/limine/
	cp assets/limine/limine-uefi-cd.bin $(ISO_DIR)/limine/
	cp $(KERNEL_ELF) $(ISO_DIR)/kernel.elf
	$(XORRISO) $(XORRISOFLAGS) $(ISO_DIR) -o $@

run: $(ISO_IMAGE)
	$(QEMU) $(QEMUFLAGS) $(ISO_IMAGE)

$(MLIBC_STAMP): build-mlibc assets/mlibc.patch
	ARCH=x86_64 CC="$(MLIBC_CC)" CXX="$(MLIBC_CXX)" \
	    CFLAGS="$(MLIBC_CFLAGS)" CXXFLAGS="$(MLIBC_CXXFLAGS)" \
	    ./build-mlibc
	@touch $@

$(MLIBC_RUNTIME_LIBS): $(MLIBC_STAMP)

mlibc: $(MLIBC_STAMP)

clean:
	@$(if $(strip $(CLEAN_FILES)),rm -rf $(CLEAN_FILES),:)

distclean:
	rm -rf $(BUILD_DIR)
