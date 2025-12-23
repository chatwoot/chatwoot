# Skiptrace [![Build Status](https://travis-ci.org/gsamokovarov/skiptrace.svg?branch=master)](https://travis-ci.org/gsamokovarov/skiptrace)

When Ruby raises an exception, it leaves you a backtrace to help you figure out
where did the exception originated in. Skiptrace gives you the bindings as well.
This can help you introspect the state of the Ruby program when at the point
the exception occurred.

## Usage

**Do not** use this gem on production environments. The performance penalty isn't
worth it anywhere outside of development.

### API

Skiptrace defines the following API:

#### Exception#bindings

Returns all the bindings up to the one in which the exception originated in.

#### Exception#binding_locations

Returns an array of `Skiptrace::Location` objects that are like [`Thread::Backtrace::Location`](https://ruby-doc.org/core-2.6.3/Thread/Backtrace/Location.html)
but also carry a `Binding` object for that frame through the `#binding` method.

#### Skiptrace.current_bindings

Returns all of the current Ruby execution state bindings. The first one is the
current one, the second is the caller one, the third is the caller of the
caller one and so on.

## Support

### CRuby

CRuby 2.5.0 and above is supported.

### JRuby

To get the best support, run JRuby in interpreted mode.

```bash
export JRUBY_OPTS=--dev
```

Only JRuby 9k is supported.

### Rubinius

Internal errors like `ZeroDevisionError` aren't caught.

## Credits

Thanks to John Mair for his work on binding_of_caller, which is a huge
inspiration. Thanks to Charlie Somerville for better_errors where the idea
comes from. Thanks to Koichi Sasada for the debug inspector API in CRuby.
