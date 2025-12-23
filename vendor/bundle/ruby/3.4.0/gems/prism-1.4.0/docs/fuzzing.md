# Fuzzing

We use fuzzing to test the various entrypoints to the library. The fuzzer we use is [AFL++](https://aflplus.plus). All files related to fuzzing live within the `fuzz` directory, which has the following structure:

```
fuzz
├── corpus
│   ├── parse             fuzzing corpus for parsing (a symlink to our fixtures)
│   └── regexp            fuzzing corpus for regexp
├── dict                  a AFL++ dictionary containing various tokens
├── docker
│   └── Dockerfile        for building a container with the fuzzer toolchain
├── fuzz.c                generic entrypoint for fuzzing
├── heisenbug.c           entrypoint for reproducing a crash or hang
├── parse.c               fuzz handler for parsing
├── parse.sh              script to run parsing fuzzer
├── regexp.c              fuzz handler for regular expression parsing
├── regexp.sh             script to run regexp fuzzer
└── tools
    ├── backtrace.sh      generates backtrace files for a crash directory
    └── minimize.sh       generates minimized crash or hang files
```

## Usage

There are currently three fuzzing targets

- `pm_serialize_parse` (parse)
- `pm_regexp_parse` (regexp)

Respectively, fuzzing can be performed with

```
make fuzz-run-parse
make fuzz-run-regexp
```

To end a fuzzing job, interrupt with CTRL+C. To enter a container with the fuzzing toolchain and debug utilities, run

```
make fuzz-debug
```

# Out-of-bounds reads

Currently, encoding functionality implementing the `pm_encoding_t` interface can read outside of inputs. For the time being, ASAN instrumentation is disabled for functions from src/enc. See `fuzz/asan.ignore`.

To disable ASAN read instrumentation globally, use the `FUZZ_FLAGS` environment variable e.g.

```
FUZZ_FLAGS="-mllvm -asan-instrument-reads=false" make fuzz-run-parse
```

Note, that this may make reproducing bugs difficult as they may depend on memory outside of the input buffer. In that case, try

```
make fuzz-debug # enter the docker container with build tools
make build/fuzz.heisenbug.parse # or .regexp
./build/fuzz.heisenbug.parse path-to-problem-input
```

# Triaging Crashes and Hangs

Triaging crashes and hangs is easier when the inputs are as short as possible. In the fuzz container, an entire crash or hang directory can be minimized using

```
./fuzz/tools/minimize.sh <directory>
```

e.g.
```
./fuzz/tools/minimize.sh fuzz/output/parse/default/crashes
```

This may take a long time. In the crash/hang directory, for each input file there will appear a minimized version with the extension `.min` appended.

Backtraces for crashes (not hangs) can be generated en masse with

```
./fuzz/tools/backtrace.sh <directory>
```

Files with basename equal to the input file name with extension `.bt` will be created e.g.

```
id:000000,sig:06,src:000006+000190,time:8480,execs:18929,op:splice,rep:4
id:000000,sig:06,src:000006+000190,time:8480,execs:18929,op:splice,rep:4.bt
```
