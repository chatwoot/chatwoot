# Testing - test/rackup/ci-*.ru files

## Overview

Puma should efficiently handle a variety of response bodies, varying both by size
and by the type of object used for the body.

Five rackup files are located in 'test/rackup' that can be used.  All have their
request body size (in kB) set via `Body-Conf` header or with `ENV['CI_BODY_CONF']`.
Additionally, the ci_select.ru file can have it's body type set via a starting
character.

* **ci_array.ru** - body is an `Array` of 1kB strings.  `Content-Length` is not set.
* **ci_chunked.ru** - body is an `Enumerator` of 1kB strings.  `Content-Length` is not set.
* **ci_io.ru** - body is a File/IO object.  `Content-Length` is set.
* **ci_string.ru** - body is a single string.  `Content-Length` is set.
* **ci_select.ru** - can be any of the above.

All responses have 25 headers, total length approx 1kB.  ci_array.ru and ci_chunked.ru
contain 1kB items.

All can be delayed by a float value (seconds) specified by the `Dly` header

Note that rhe `Body-Conf` header takes precedence, and `ENV['CI_BODY_CONF']` is
only read on load.

## ci_select.ru

The ci_select.ru file allows a starting character to specify the body type in the
`Body-Conf` header or with `ENV['CI_BODY_CONF']`.
* **a** - array of strings
* **c** - chunked (enum)
* **s** - single string
* **i** - File/IO

A value of `a100` would return a body as an array of 100 1kB strings.
