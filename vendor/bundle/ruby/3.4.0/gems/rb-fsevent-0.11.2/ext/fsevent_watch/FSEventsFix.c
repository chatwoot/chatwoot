/*
 * FSEventsFix
 *
 * Resolves a long-standing bug in realpath() that prevents FSEvents API from
 * monitoring certain folders on a wide range of OS X released (10.6-10.10 at least).
 *
 * The underlying issue is that for some folders, realpath() call starts returning
 * a path with incorrect casing (e.g. "/users/smt" instead of "/Users/smt").
 * FSEvents is case-sensitive and calls realpath() on the paths you pass in, so
 * an incorrect value returned by realpath() prevents FSEvents from seeing any
 * change events.
 *
 * See the discussion at https://github.com/thibaudgg/rb-fsevent/issues/10 about
 * the history of this bug and how this library came to exist.
 *
 * This library uses Facebook's fishhook to replace a custom implementation of
 * realpath in place of the system realpath; FSEvents will then invoke our custom
 * implementation (which does not screw up the names) and will thus work correctly.
 *
 * Our implementation of realpath is based on the open-source implementation from
 * OS X 10.10, with a single change applied (enclosed in "BEGIN WORKAROUND FOR
 * OS X BUG" ... "END WORKAROUND FOR OS X BUG").
 *
 * Include FSEventsFix.{h,c} into your project and call FSEventsFixInstall().
 *
 * It is recommended that you install FSEventsFix on demand, using FSEventsFixIsBroken
 * to check if the folder you're about to pass to FSEventStreamCreate needs the fix.
 * Note that the fix must be applied before calling FSEventStreamCreate.
 *
 * FSEventsFixIsBroken requires a path that uses the correct case for all folder names,
 * i.e. a path provided by the system APIs or constructed from folder names provided
 * by the directory enumeration APIs.
 *
 * Copyright (c) 2015 Andrey Tarantsov <andrey@tarantsov.com>
 * Copyright (c) 2003 Constantin S. Svintsoff <kostik@iclub.nsu.ru>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Based on a realpath implementation from Apple libc 498.1.7, taken from
 * http://www.opensource.apple.com/source/Libc/Libc-498.1.7/stdlib/FreeBSD/realpath.c
 * and provided under the following license:
 *
 * Copyright (c) 2003 Constantin S. Svintsoff <kostik@iclub.nsu.ru>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The names of the authors may not be used to endorse or promote
 *    products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


#include "FSEventsFix.h"

#include <dispatch/dispatch.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <dlfcn.h>


const char *const FSEventsFixVersionString = "0.11.0";


#pragma mark - Forward declarations

static char *(*orig_realpath)(const char *restrict file_name, char resolved_name[PATH_MAX]);
static char *CFURL_realpath(const char *restrict file_name, char resolved_name[PATH_MAX]);
static char *FSEventsFix_realpath_wrapper(const char *restrict src, char *restrict dst);

static void _FSEventsFixHookInstall();
static void _FSEventsFixHookUninstall();


#pragma mark - Internal state

static dispatch_queue_t g_queue = NULL;

static int64_t g_enable_refcount = 0;

static bool g_in_self_test = false;
static bool g_hook_operational = false;

static void(^g_logging_block)(FSEventsFixMessageType type, const char *message);
static FSEventsFixDebugOptions g_debug_opt = 0;

typedef struct {
    char *name;
    void *replacement;
    void *original;
    uint hooked_symbols;
} rebinding_t;

static rebinding_t g_rebindings[] = {
    { "_realpath$DARWIN_EXTSN", (void *) &FSEventsFix_realpath_wrapper, (void *) &realpath, 0 }
};
static const uint g_rebindings_nel = sizeof(g_rebindings) / sizeof(g_rebindings[0]);


#pragma mark - Logging

static void _FSEventsFixLog(FSEventsFixMessageType type, const char *__restrict fmt, ...) __attribute__((__format__ (__printf__, 2, 3)));

static void _FSEventsFixLog(FSEventsFixMessageType type, const char *__restrict fmt, ...) {
    if (g_logging_block) {
        char *message = NULL;
        va_list va;
        va_start(va, fmt);
        vasprintf(&message, fmt, va);
        va_end(va);

        if (message) {
            if (!!(g_debug_opt & FSEventsFixDebugOptionLogToStderr)) {
                fprintf(stderr, "FSEventsFix: %s\n", message);
            }
            if (g_logging_block) {
                g_logging_block(type, message);
            }
            free(message);
        }
    }
}


#pragma mark - API

void _FSEventsFixInitialize() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_queue = dispatch_queue_create("FSEventsFix", DISPATCH_QUEUE_SERIAL);
    });
}

void FSEventsFixConfigure(FSEventsFixDebugOptions debugOptions, void(^loggingBlock)(FSEventsFixMessageType severity, const char *message)) {
    _FSEventsFixInitialize();
    loggingBlock = Block_copy(loggingBlock);
    dispatch_sync(g_queue, ^{
        g_debug_opt = debugOptions;
        g_logging_block = loggingBlock;
    });
}

// Must be called from the private serial queue.
void _FSEventsFixSelfTest() {
    g_in_self_test = true;
    g_hook_operational = false;
    static char result[1024];
    realpath("/Etc/__!FSEventsFixSelfTest!__", result);
    g_in_self_test = false;
}

void FSEventsFixEnable() {
    _FSEventsFixInitialize();
    dispatch_sync(g_queue, ^{
        if (++g_enable_refcount == 1) {
            orig_realpath = dlsym(RTLD_DEFAULT, "realpath");
            _FSEventsFixHookInstall();
            _FSEventsFixSelfTest();
            if (g_hook_operational) {
                _FSEventsFixLog(FSEventsFixMessageTypeStatusChange, "Enabled");
            } else {
                _FSEventsFixLog(FSEventsFixMessageTypeFatalError, "Failed to enable (hook not called)");
            }
        }
    });
}

void FSEventsFixDisable() {
    _FSEventsFixInitialize();
    dispatch_sync(g_queue, ^{
        if (g_enable_refcount == 0) {
            abort();
        }
        if (--g_enable_refcount == 0) {
            _FSEventsFixHookUninstall();
            _FSEventsFixSelfTest();
            if (!g_hook_operational) {
                _FSEventsFixLog(FSEventsFixMessageTypeStatusChange, "Disabled");
            } else {
                _FSEventsFixLog(FSEventsFixMessageTypeFatalError, "Failed to disable (hook still called)");
            }
        }
    });
}

bool FSEventsFixIsOperational() {
    _FSEventsFixInitialize();
    __block bool result = false;
    dispatch_sync(g_queue, ^{
        result = g_hook_operational;
    });
    return result;
}

bool _FSEventsFixIsBroken_noresolve(const char *resolved) {
    if (!!(g_debug_opt & FSEventsFixDebugOptionSimulateBroken)) {
        if (strstr(resolved, FSEventsFixSimulatedBrokenFolderMarker)) {
            return true;
        }
    }

    char *reresolved = realpath(resolved, NULL);
    if (reresolved) {
        bool broken = (0 != strcmp(resolved, reresolved));
        free(reresolved);
        return broken;
    } else {
        return true;
    }
}

bool FSEventsFixIsBroken(const char *path) {
    char *resolved = CFURL_realpath(path, NULL);
    if (!resolved) {
        return true;
    }
    bool broken = _FSEventsFixIsBroken_noresolve(resolved);
    free(resolved);
    return broken;
}

char *FSEventsFixCopyRootBrokenFolderPath(const char *inpath) {
    if (!FSEventsFixIsBroken(inpath)) {
        return NULL;
    }

    // get a mutable copy of an absolute path
    char *path = CFURL_realpath(inpath, NULL);
    if (!path) {
        return NULL;
    }

    for (;;) {
        char *sep = strrchr(path, '/');
        if ((sep == NULL) || (sep == path)) {
            break;
        }
        *sep = 0;
        if (!_FSEventsFixIsBroken_noresolve(path)) {
            *sep = '/';
            break;
        }
    }

    return path;
}

static void _FSEventsFixAttemptRepair(const char *folder) {
    int rv = rename(folder, folder);

    if (!!(g_debug_opt & FSEventsFixDebugOptionSimulateRepair)) {
        const char *pos = strstr(folder, FSEventsFixSimulatedBrokenFolderMarker);
        if (pos) {
            char *fixed = strdup(folder);
            fixed[pos - folder] = 0;
            strcat(fixed, pos + strlen(FSEventsFixSimulatedBrokenFolderMarker));

            rv = rename(folder, fixed);
            free(fixed);
        }
    }

    if (rv != 0) {
        if (errno == EPERM) {
            _FSEventsFixLog(FSEventsFixMessageTypeResult, "Permission error when trying to repair '%s'", folder);
        } else {
            _FSEventsFixLog(FSEventsFixMessageTypeExpectedFailure, "Unknown error when trying to repair '%s': errno = %d", folder, errno);
        }
    }
}

FSEventsFixRepairStatus FSEventsFixRepairIfNeeded(const char *inpath) {
    char *root = FSEventsFixCopyRootBrokenFolderPath(inpath);
    if (root == NULL) {
        return FSEventsFixRepairStatusNotBroken;
    }

    for (;;) {
        _FSEventsFixAttemptRepair(root);
        char *newRoot = FSEventsFixCopyRootBrokenFolderPath(inpath);
        if (newRoot == NULL) {
            _FSEventsFixLog(FSEventsFixMessageTypeResult, "Repaired '%s' in '%s'", root, inpath);
            free(root);
            return FSEventsFixRepairStatusRepaired;
        }
        if (0 == strcmp(root, newRoot)) {
            _FSEventsFixLog(FSEventsFixMessageTypeResult, "Failed to repair '%s' in '%s'", root, inpath);
            free(root);
            free(newRoot);
            return FSEventsFixRepairStatusFailed;
        }
        _FSEventsFixLog(FSEventsFixMessageTypeResult, "Partial success, repaired '%s' in '%s'", root, inpath);
        free(root);
        root = newRoot;
    }
}


#pragma mark - FSEventsFix realpath wrapper

static char *FSEventsFix_realpath_wrapper(const char * __restrict src, char * __restrict dst) {
    if (g_in_self_test) {
        if (strstr(src, "__!FSEventsFixSelfTest!__")) {
            g_hook_operational = true;
        }
    }

    // CFURL_realpath doesn't support putting where resolution failed into the
    // dst buffer, so we call the original realpath here first and if it gets a
    // result, replace that with the output of CFURL_realpath. that way all the
    // features of the original realpath are available.
    char *rv = NULL;
    char *orv = orig_realpath(src, dst);
    if (orv != NULL) { rv = CFURL_realpath(src, dst); }

    if (!!(g_debug_opt & FSEventsFixDebugOptionLogCalls)) {
        char *result = rv ?: dst;
        _FSEventsFixLog(FSEventsFixMessageTypeCall, "realpath(%s) => %s\n", src, result);
    }

    if (!!(g_debug_opt & FSEventsFixDebugOptionUppercaseReturn)) {
        char *result = rv ?: dst;
        if (result) {
            for (char *pch = result; *pch; ++pch) {
                *pch = (char)toupper(*pch);
            }
        }
    }

    return rv;
}


#pragma mark - realpath

// naive implementation of realpath on top of CFURL
// NOTE: doesn't quite support the full range of errno results one would
// expect here, in part because some of these functions just return a boolean,
// and in part because i'm not dealing with messy CFErrorRef objects and
// attempting to translate those to sane errno values.
// NOTE: the OSX realpath will return _where_ resolution failed in resolved_name
// if passed in and return NULL. we can't properly support that extension here
// since the resolution happens entirely behind the scenes to us in CFURL.
static char* CFURL_realpath(const char *file_name, char resolved_name[PATH_MAX])
{
    char* resolved;
    CFURLRef url1;
    CFURLRef url2;
    CFStringRef path;

    if (file_name == NULL) {
        errno = EINVAL;
        return (NULL);
    }

#if __DARWIN_UNIX03
    if (*file_name == 0) {
        errno = ENOENT;
        return (NULL);
    }
#endif

    // create a buffer to store our result if we weren't passed one
    if (!resolved_name) {
        if ((resolved = malloc(PATH_MAX)) == NULL) return (NULL);
    } else {
        resolved = resolved_name;
    }

    url1 = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8*)file_name, (CFIndex)strlen(file_name), false);
    if (url1 == NULL) { goto error_return; }

    url2 = CFURLCopyAbsoluteURL(url1);
    CFRelease(url1);
    if (url2 == NULL) { goto error_return; }

    url1 = CFURLCreateFileReferenceURL(NULL, url2, NULL);
    CFRelease(url2);
    if (url1 == NULL) { goto error_return; }

    // if there are multiple hard links to the original path, this may end up
    // being _completely_ different from what was intended
    url2 = CFURLCreateFilePathURL(NULL, url1, NULL);
    CFRelease(url1);
    if (url2 == NULL) { goto error_return; }

    path = CFURLCopyFileSystemPath(url2, kCFURLPOSIXPathStyle);
    CFRelease(url2);
    if (path == NULL) { goto error_return; }

    bool success = CFStringGetCString(path, resolved, PATH_MAX, kCFStringEncodingUTF8);
    CFRelease(path);
    if (!success) { goto error_return; }

    return resolved;

error_return:
    if (!resolved_name) {
        // we weren't passed in an output buffer and created our own. free it
        int e = errno;
        free(resolved);
        errno = e;
    }
    return (NULL);
}


#pragma mark - fishhook

// Copyright (c) 2013, Facebook, Inc.
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//   * Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//   * Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//   * Neither the name Facebook nor the names of its contributors may be used to
//     endorse or promote products derived from this software without specific
//     prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <stdlib.h>
#import <string.h>
#import <sys/types.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

static volatile bool g_hook_installed = false;

static void _FSEventsFixHookUpdateSection(section_t *section, intptr_t slide, nlist_t *symtab, char *strtab, uint32_t *indirect_symtab)
{
    uint32_t *indirect_symbol_indices = indirect_symtab + section->reserved1;
    void **indirect_symbol_bindings = (void **)((uintptr_t)slide + section->addr);
    for (uint i = 0; i < section->size / sizeof(void *); i++) {
        uint32_t symtab_index = indirect_symbol_indices[i];
        if (symtab_index == INDIRECT_SYMBOL_ABS || symtab_index == INDIRECT_SYMBOL_LOCAL ||
            symtab_index == (INDIRECT_SYMBOL_LOCAL   | INDIRECT_SYMBOL_ABS)) {
            continue;
        }
        uint32_t strtab_offset = symtab[symtab_index].n_un.n_strx;
        char *symbol_name = strtab + strtab_offset;
        for (rebinding_t *cur = g_rebindings, *end = g_rebindings + g_rebindings_nel; cur < end; ++cur)  {
            if (strcmp(symbol_name, cur->name) == 0) {
                if (g_hook_installed) {
                    if (indirect_symbol_bindings[i] != cur->replacement) {
                        indirect_symbol_bindings[i] = cur->replacement;
                        ++cur->hooked_symbols;
                    }
                } else if (cur->original != NULL) {
                    if (indirect_symbol_bindings[i] == cur->replacement) {
                        indirect_symbol_bindings[i] = cur->original;
                        if (cur->hooked_symbols > 0) {
                            --cur->hooked_symbols;
                        }
                    }
                }
                goto symbol_loop;
            }
        }
    symbol_loop:;
    }
}

static void _FSEventsFixHookUpdateImage(const struct mach_header *header, intptr_t slide) {
    Dl_info info;
    if (dladdr(header, &info) == 0) {
        return;
    }

    segment_command_t *cur_seg_cmd;
    segment_command_t *linkedit_segment = NULL;
    struct symtab_command* symtab_cmd = NULL;
    struct dysymtab_command* dysymtab_cmd = NULL;

    uintptr_t cur = (uintptr_t)header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_LINKEDIT) == 0) {
                linkedit_segment = cur_seg_cmd;
            }
        } else if (cur_seg_cmd->cmd == LC_SYMTAB) {
            symtab_cmd = (struct symtab_command*)cur_seg_cmd;
        } else if (cur_seg_cmd->cmd == LC_DYSYMTAB) {
            dysymtab_cmd = (struct dysymtab_command*)cur_seg_cmd;
        }
    }

    if (!symtab_cmd || !dysymtab_cmd || !linkedit_segment ||
        !dysymtab_cmd->nindirectsyms) {
        return;
    }

    // Find base symbol/string table addresses
    uintptr_t linkedit_base = (uintptr_t)slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
    nlist_t *symtab = (nlist_t *)(linkedit_base + symtab_cmd->symoff);
    char *strtab = (char *)(linkedit_base + symtab_cmd->stroff);

    // Get indirect symbol table (array of uint32_t indices into symbol table)
    uint32_t *indirect_symtab = (uint32_t *)(linkedit_base + dysymtab_cmd->indirectsymoff);

    cur = (uintptr_t)header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_DATA) != 0) {
                continue;
            }
            for (uint j = 0; j < cur_seg_cmd->nsects; j++) {
                section_t *sect =
                (section_t *)(cur + sizeof(segment_command_t)) + j;
                if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS) {
                    _FSEventsFixHookUpdateSection(sect, slide, symtab, strtab, indirect_symtab);
                }
                if ((sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
                    _FSEventsFixHookUpdateSection(sect, slide, symtab, strtab, indirect_symtab);
                }
            }
        }
    }
}

static void _FSEventsFixHookSaveOriginals() {
    for (rebinding_t *cur = g_rebindings, *end = g_rebindings + g_rebindings_nel; cur < end; ++cur)  {
        void *original = cur->original = dlsym(RTLD_DEFAULT, cur->name+1);
        if (!original) {
            const char *error = dlerror();
            _FSEventsFixLog(FSEventsFixMessageTypeFatalError, "Cannot find symbol %s, dlsym says: %s\n", cur->name, error);
        }
    }
}

static void _FSEventsFixHookUpdate() {
    uint32_t c = _dyld_image_count();
    for (uint32_t i = 0; i < c; i++) {
        _FSEventsFixHookUpdateImage(_dyld_get_image_header(i), _dyld_get_image_vmaddr_slide(i));
    }
}

static void _FSEventsFixHookInstall() {
    static bool first_rebinding_done = false;

    if (!g_hook_installed) {
        g_hook_installed = true;

        if (!first_rebinding_done) {
            first_rebinding_done = true;
            _FSEventsFixHookSaveOriginals();
            _dyld_register_func_for_add_image(_FSEventsFixHookUpdateImage);
        } else {
            _FSEventsFixHookUpdate();
        }
    }
}

static void _FSEventsFixHookUninstall() {
    if (g_hook_installed) {
        g_hook_installed = false;
        _FSEventsFixHookUpdate();
    }
}
