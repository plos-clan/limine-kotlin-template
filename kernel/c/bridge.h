#ifndef BRIDGE_H
#define BRIDGE_H

#include <limine.h>

#ifdef __cplusplus
extern "C" {
#endif

extern volatile struct limine_framebuffer_request framebuffer_request;
extern volatile struct limine_stack_size_request stack_size_request;
extern volatile struct limine_hhdm_request hhdm_request;
extern volatile struct limine_memmap_request memmap_request;
extern volatile struct limine_mp_request mp_request;
extern volatile struct limine_rsdp_request rsdp_request;
extern volatile struct limine_executable_file_request executable_file_request;

#ifdef __cplusplus
}
#endif

#endif
