
# throttle

  Throttle a function

## Installation

    $ component install component/throttle

## Example

    var throttle = require('throttle');
    window.onresize = throttle(resize, 200);

    function resize(e) {
      console.log('height', window.innerHeight);
      console.log('width', window.innerWidth);
    }

## API

### throttle(fn, wait)

Creates a function that will call `fn` at most once every `wait` milliseconds.

Supports leading and trailing invocation.

`fn` will receive last context (`this`) and last arguments passed to a throttled wrapper before `fn` was invoked.

## License

  MIT
