# hana

* http://github.com/tenderlove/hana

## DESCRIPTION:

Implementation of [JSON Patch][1] and [JSON Pointer][2] RFC.

## FEATURES/PROBLEMS:

Implements specs of the [JSON Patch][1] and [JSON pointer][2] RFCs:

This works against Ruby objects, so you should load the JSON to Ruby,
process it, then emit as JSON again.

## SYNOPSIS:

```ruby
patch = Hana::Patch.new [
  { 'op' => 'add', 'path' => '/baz', 'value' => 'qux' }
]

patch.apply('foo' => 'bar') # => {'baz' => 'qux', 'foo' => 'bar'}
```

## REQUIREMENTS:

* Ruby

## INSTALL:

    $ gem install hana

## LICENSE:

(The MIT License)

Copyright (c) 2012-2020 Aaron Patterson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[1]: https://datatracker.ietf.org/doc/rfc6902/
[2]: http://tools.ietf.org/html/rfc6901
