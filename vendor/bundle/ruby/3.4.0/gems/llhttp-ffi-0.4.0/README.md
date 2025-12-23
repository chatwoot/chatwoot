# llhttp-ffi

Ruby FFI bindings for [llhttp](https://github.com/nodejs/llhttp).

## Install

```
gem install llhttp-ffi
```

## Usage

```ruby
require "llhttp"

# Define a delegate class for handling callbacks:
#
class Delegate < LLHttp::Delegate
  def on_message_begin
    ...
  end
end

delegate = Delegate.new

# Create a parser:
#
parser = LLHttp::Parser.new(delegate)

# Parse a request:
#
parser << "GET / HTTP/1.1\r\n\r\n"

# Reset the parser for the next request:
#
parser.reset
```
