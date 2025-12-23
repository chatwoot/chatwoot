# Oj Install Options

### Enable trace log

```
$ gem install oj -- --enable-trace-log
```

To enable Oj trace feature, it uses `--enable-trace-log` option when installing the gem.
Then, the trace logs will be displayed when `:trace` option is set to `true`.


### Enable SIMD instructions

```
$ gem install oj -- --with-sse42
```

To enable the use of SIMD instructions in Oj, it uses the `--with-sse42` option when installing the gem.
This will enable the use of the SSE4.2 instructions in the internal.
