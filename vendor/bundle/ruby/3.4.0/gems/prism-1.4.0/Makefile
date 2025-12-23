
# V=0 quiet, V=1 verbose.  other values don't work.
V = 0
V0 = $(V:0=)
Q1 = $(V:1=)
Q = $(Q1:0=@)
ECHO1 = $(V:1=@ :)
ECHO = $(ECHO1:0=@ echo)
FUZZ_OUTPUT_DIR = $(CURDIR)/fuzz/output

SOEXT ?= $(shell ruby -e 'puts RbConfig::CONFIG["SOEXT"]')

CPPFLAGS := -Iinclude $(CPPFLAGS)
CFLAGS := -g -O2 -std=c99 -Wall -Werror -Wextra -Wpedantic -Wundef -Wconversion -Wno-missing-braces -fPIC -fvisibility=hidden -Wimplicit-fallthrough $(CFLAGS)
CC ?= cc
AR ?= ar
WASI_SDK_PATH := /opt/wasi-sdk

MAKEDIRS ?= mkdir -p
RMALL ?= rm -f -r

HEADERS := $(wildcard include/*.h include/*/*.h include/*/*/*.h')
SOURCES := $(wildcard src/*.c src/*/*.c)
SHARED_OBJECTS := $(subst src/,build/shared/,$(SOURCES:.c=.o))
STATIC_OBJECTS := $(subst src/,build/static/,$(SOURCES:.c=.o))

all: shared static

shared: build/libprism.$(SOEXT)
static: build/libprism.a
wasm: javascript/src/prism.wasm
java-wasm: java-wasm/src/test/resources/prism.wasm

build/libprism.$(SOEXT): $(SHARED_OBJECTS)
	$(ECHO) "linking $@ with $(CC)"
	$(Q) $(CC) $(DEBUG_FLAGS) $(CFLAGS) -shared -o $@ $(SHARED_OBJECTS)

build/libprism.a: $(STATIC_OBJECTS)
	$(ECHO) "building $@ with $(AR)"
	$(Q) $(AR) $(ARFLAGS) $@ $(STATIC_OBJECTS) $(Q1:0=>/dev/null)

javascript/src/prism.wasm: Makefile $(SOURCES) $(HEADERS)
	$(ECHO) "building $@"
	$(Q) $(WASI_SDK_PATH)/bin/clang --sysroot=$(WASI_SDK_PATH)/share/wasi-sysroot/ $(DEBUG_FLAGS) -DPRISM_EXPORT_SYMBOLS -D_WASI_EMULATED_MMAN -lwasi-emulated-mman $(CPPFLAGS) $(CFLAGS) -Wl,--export-all -Wl,--no-entry -mexec-model=reactor -o $@ $(SOURCES)

java-wasm/src/test/resources/prism.wasm: Makefile $(SOURCES) $(HEADERS)
	$(ECHO) "building $@"
	$(Q) $(WASI_SDK_PATH)/bin/clang $(DEBUG_FLAGS) -DPRISM_EXPORT_SYMBOLS -D_WASI_EMULATED_MMAN -lwasi-emulated-mman $(CPPFLAGS) $(CFLAGS) -Wl,--export-all -Wl,--no-entry -mexec-model=reactor -lc++ -lc++abi -o $@ $(SOURCES)

build/shared/%.o: src/%.c Makefile $(HEADERS)
	$(ECHO) "compiling $@"
	$(Q) $(MAKEDIRS) $(@D)
	$(Q) $(CC) $(DEBUG_FLAGS) -DPRISM_EXPORT_SYMBOLS $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

build/static/%.o: src/%.c Makefile $(HEADERS)
	$(ECHO) "compiling $@"
	$(Q) $(MAKEDIRS) $(@D)
	$(Q) $(CC) $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

build/fuzz.%: $(SOURCES) fuzz/%.c fuzz/fuzz.c
	$(ECHO) "building $* fuzzer"
	$(Q) $(MAKEDIRS) $(@D)
	$(ECHO) "building main fuzz binary"
	$(Q) AFL_HARDEN=1 afl-clang-lto $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(FUZZ_FLAGS) -O0 -fsanitize-ignorelist=fuzz/asan.ignore -fsanitize=fuzzer,address -ggdb3 -std=c99 -Iinclude -o $@ $^
	$(ECHO) "building cmplog binary"
	$(Q) AFL_HARDEN=1 AFL_LLVM_CMPLOG=1 afl-clang-lto $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(FUZZ_FLAGS) -O0 -fsanitize-ignorelist=fuzz/asan.ignore -fsanitize=fuzzer,address -ggdb3 -std=c99 -Iinclude -o $@.cmplog $^

build/fuzz.heisenbug.%: $(SOURCES) fuzz/%.c fuzz/heisenbug.c
	$(Q) AFL_HARDEN=1 afl-clang-lto $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(FUZZ_FLAGS) -O0 -fsanitize-ignorelist=fuzz/asan.ignore -fsanitize=fuzzer,address -ggdb3 -std=c99 -Iinclude -o $@ $^

fuzz-debug:
	$(ECHO) "entering debug shell"
	$(Q) docker run -it --rm -e HISTFILE=/prism/fuzz/output/.bash_history -v $(CURDIR):/prism -v $(FUZZ_OUTPUT_DIR):/fuzz_output prism/fuzz

fuzz-docker-build: fuzz/docker/Dockerfile
	$(ECHO) "building docker image"
	$(Q) docker build -t prism/fuzz fuzz/docker/

fuzz-run-%: FORCE fuzz-docker-build
	$(ECHO) "generating templates"
	$(Q) bundle exec rake templates
	$(ECHO) "running $* fuzzer"
	$(Q) docker run --rm -v $(CURDIR):/prism prism/fuzz /bin/bash -c "FUZZ_FLAGS=\"$(FUZZ_FLAGS)\" make build/fuzz.$*"
	$(ECHO) "starting AFL++ run"
	$(Q) $(MAKEDIRS) $(FUZZ_OUTPUT_DIR)/$*
	$(Q) docker run -it --rm -v $(CURDIR):/prism -v $(FUZZ_OUTPUT_DIR):/fuzz_output prism/fuzz /bin/bash -c "./fuzz/$*.sh /fuzz_output/$*"
FORCE:

fuzz-clean:
	$(Q) $(RMALL) fuzz/output

clean:
	$(Q) $(RMALL) build

.PHONY: clean fuzz-clean

all-no-debug: DEBUG_FLAGS := -DNDEBUG=1
all-no-debug: OPTFLAGS := -O3
all-no-debug: all

minimal: CFLAGS := $(CFLAGS) -DPRISM_BUILD_MINIMAL
minimal: all

run: Makefile $(STATIC_OBJECTS) $(HEADERS) test.c
	$(ECHO) "compiling test.c"
	$(Q) $(CC) $(CPPFLAGS) $(CFLAGS) $(STATIC_OBJECTS) test.c
	$(ECHO) "running test.c"
	$(Q) ./a.out
