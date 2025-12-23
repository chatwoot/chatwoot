.PHONY: all clean check coverage

gumbo_objs := $(patsubst %.c,build/%.o,$(wildcard src/*.c))
test_objs := $(patsubst %.cc,build/%.o,$(wildcard test/*.cc))
gtest_lib := googletest/make/gtest_main.a

# make SANITIZEFLAGS='-fsanitize=undefined -fsanitize=address'
SANITIZEFLAGS :=
CPPFLAGS := -Isrc
CFLAGS := -std=c99 -Os -Wall
CXXFLAGS := -isystem googletest/include -std=c++11 -Os -Wall
LDFLAGS := -pthread

all: check

oss-fuzz:
	./fuzzer/build-ossfuzz.sh

fuzzers: fuzzer-normal fuzzer-asan fuzzer-ubsan fuzzer-msan

fuzzer-normal:
	./fuzzer/build.sh

fuzzer-asan:
	SANITIZER=asan ./fuzzer/build.sh

fuzzer-ubsan:
	SANITIZER=ubsan ./fuzzer/build.sh

fuzzer-msan:
	SANITIZER=msan ./fuzzer/build.sh

# don't try to regenerate ragel or gperf files in CI, that should be a development-only action and
# the generated files should be committed to SCM
ifneq ($(CI),true)
src/foreign_attrs.c: src/foreign_attrs.gperf
	gperf -m100 -n $< | ./gperf-filter.sed > $@

src/%.c: src/%.gperf
	gperf -m100 $< | ./gperf-filter.sed > $@

src/%.c: src/%.rl
	ragel -F1 -o $@ $<
endif

build/src:
	mkdir -p $@

build/test:
	mkdir -p $@

build/src/%.o: src/%.c build/src/flags | build/src
	$(CC) -MMD $(CPPFLAGS) $(CFLAGS) $(SANITIZEFLAGS) -c -o $@ $<

build/test/%.o: test/%.cc build/test/flags | build/test
	$(CXX) -MMD $(CPPFLAGS) $(CXXFLAGS) $(SANITIZEFLAGS) -c -o $@ $<

build/run_tests: $(gumbo_objs) $(test_objs) $(gtest_lib)
	$(CXX) -o $@ $+ $(LDFLAGS) $(SANITIZEFLAGS)

check: build/run_tests
	./build/run_tests

coverage:
	$(RM) build/{src,test}/*.gcda
	$(RM) build/*.info
	$(MAKE) CPPFLAGS='-Isrc -DNDEBUG=1' \
		CFLAGS='-std=c99 --coverage -g -O0' \
		CXXFLAGS='-isystem googletest/include -std=c++11 --coverage -g -O0' \
		LDFLAGS='--coverage' \
		build/run_tests
	lcov	--no-external \
		--initial \
		--capture \
		--base-directory . \
		--directory build \
		--output-file build/coverage-pre.info
	awk	-F '[:,]' \
		'/^SF:/ { delete defs } /^FN:/ { defs[$$2]=1 } /^DA:/ { if ($$3 == 0 && $$2 in defs) next } { print }' \
		build/coverage-pre.info > build/coverage-initial.info
	./build/run_tests
	lcov	--no-external \
		--capture \
		--base-directory . \
		--directory build \
		--rc lcov_branch_coverage=1 \
		--output-file build/coverage-test.info
	lcov	--add-tracefile build/coverage-initial.info \
		--add-tracefile build/coverage-test.info \
		--rc lcov_branch_coverage=1 \
		--output-file build/coverage.info
	lcov	--remove build/coverage.info '$(CURDIR)/googletest/*' \
		--rc lcov_branch_coverage=1 \
		--output-file build/coverage.info
	genhtml --branch-coverage \
		--output-directory build/coverage \
		build/coverage.info

clean:
	$(RM) -r build
	$(RM) -r fuzzer/build fuzzer/src-* fuzzer/gumbo_corpus

build/src/flags: | build/src
	@echo 'old_CC := $(CC)' > $@
	@echo 'old_CPPFLAGS := $(CPPFLAGS)' >> $@
	@echo 'old_CFLAGS := $(CFLAGS)' >>$@
	@echo 'old_SANITIZEFLAGS := $(SANITIZEFLAGS)' >> $@
	@echo 'old_LDFLAGS := $(LDFLAGS)' >> $@

build/test/flags: | build/test
	@echo 'old_CXX := $(CXX)' > $@
	@echo 'old_CPPFLAGS := $(CPPFLAGS)' >> $@
	@echo 'old_CXXFLAGS := $(CXXFLAGS)' >> $@
	@echo 'old_SANITIZEFLAGS := $(SANITIZEFLAGS)' >> $@
	@echo 'old_LDFLAGS := $(LDFLAGS)' >> $@

ifeq (,$(filter clean coverage,$(MAKECMDGOALS)))
# Ensure that the flags are up to date.
-include build/src/flags build/test/flags
ifneq ($(old_CC) | $(old_CPPFLAGS) | $(old_CFLAGS) | $(old_SANITIZEFLAGS) | $(old_LDFLAGS),$(CC) | $(CPPFLAGS) | $(CFLAGS) | $(SANITIZEFLAGS) | $(LDFLAGS))
.PHONY: build/src/flags
endif
ifneq ($(old_CXX) | $(old_CPPFLAGS) | $(old_CXXFLAGS) | $(old_SANITIZEFLAGS) | $(old_LDFLAGS),$(CXX) | $(CPPFLAGS) | $(CXXFLAGS) | $(SANITIZEFLAGS) | $(LDFLAGS))
.PHONY: build/test/flags
endif

# Include dependencies.
-include $(test_objs:.o=.d) $(gumbo_objs:.o=.d)
endif
