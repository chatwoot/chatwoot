# RELEASE NOTES

The release notes here are organized by release. For a list of changes
see the See [{file:CHANGELOG.md}](CHANGELOG.md) file. In this file are
the steps to take to aid in keeping things rolling after updating to
the latest version.

## 3.13.7

The default for JSON when mimicked by Oj is now to set
`:allow_invalid_unicode`. To change that behavior JSON.load, set that
option to false.

## 3.13.x

This release included a new cache that performs better than the
earlier cache and a new high performance parser.

### Cache

The new cache includes a least recently used expiration to reduce
memory use. The cache is also self adjusting and will expand as needed
for better performance. It also handles Hash keys and string values
with two options, `:cache_keys`, a boolean and `:cache_str` an
integer. The `:cache_str` if set to more than zero is the limit for
the length of string values to cache. The maximum value is 35 which
allows strings up to 34 bytes to be cached.

One interesting aspect of the cache is not so much the string caching
which performs similar to the Ruby intern functions but the caching of
symbols and object attribute names. There is a significant gain for
symbols and object attributes.

If the cache is not desired then setting the default options to turn
it off can be done with this line:

``` ruby
Oj.default_options = { cache_keys: false, cache_str: 0 }
```

### Oj::Parser

The new parser uses a different core that follows the approach taken
by [OjC](https://github.com/ohler55/ojc) and
[OjG](https://github.com/ohler55/ojg). It also takes advantage of the
bulk Array and Hash functions. Another issue the new parser addresses
is option management. Instead of a single global default_options each
parser instance maintains it's own options.

There is a price to be paid when using the Oj::Parser. The API is not
the same the older parser. A single parser can only be used in a
single thread. This allows reuse of internal buffers for additional
improvements in performance.

The performane advantage of the Oj::Parse is that it is more than 3
times faster than the Oj::compat_load call and 6 times faster than the
JSON gem.

### Dump Performance

Thanks to Watson1978 Oj.dump also received a speed boost.
