# stdin-discarder

> Discard stdin input except for Ctrl+C

This can be useful to prevent stdin input from interfering with stdout output. For example, you are showing a spinner, and if the user presses a key, it would interfere with the spinner, causing visual glitches. This package prevents such problems.

This has no effect on Windows as there is no good way to implement discarding stdin properly there.

This package is used by [`ora`](https://github.com/sindresorhus/ora) for its [`discardStdin`](https://github.com/sindresorhus/ora#discardstdin) option.

## Install

```sh
npm install stdin-discarder
```

## Usage

```js
import stdinDiscarder from 'stdin-discarder';

stdinDiscarder.start();
```

## API

### stdinDiscarder.start()

Start discarding stdin.

### stdinDiscarder.stop()

Stop discarding stdin.

## Related

- [hook-std](https://github.com/sindresorhus/hook-std) - Hook and modify stdout and stderr
