# Embedded Scheme

Standalone Ruby interpreter targeting R7RS-small language semantics. It is under
development, is not yet R7RS-small compliant, and is not wired into Apropos or Ask.

```ruby
require_relative 'lib/scheme'

runtime = Scheme::Runtime.new
runtime.evaluate('(map car (list (list 1 2) (list 3 4)))')
# Scheme list containing 1 and 3
```

## Preloaded environment

Every implemented procedure and syntax form is available when a runtime is
created. Programs do not need imports. An `import` form returns an unspecified
value without evaluating its contents or changing bindings.

There is no library loader, dependency resolution, or filesystem access through
imports. All import declarations are ignored, including `only`, `except`,
`prefix`, and `rename`: they neither restrict names nor create aliases. An
ignored import does not make an unimplemented procedure available; calling it
still raises an unbound-identifier error.

This intentionally differs from the R7RS-small library system. R7RS-small is the
reference for language behavior, not a current conformance claim.

## Tests

```sh
bundle exec rspec spec/lib/scheme
```

Tests exercise the reader, standard procedures, lexical evaluation, tail calls,
continuations, dynamic bindings, exceptions, promises, records, and inert imports.
They do not constitute a complete R7RS-small conformance suite.

Boundary and interaction tests also cover overlapping copies, disjoint vector
and bytevector types, Unicode and datum round trips, shared and cyclic data,
exception propagation across dynamic extents, reusable continuations in collection
callbacks, promise reentrancy, reader nesting, and evaluation budget exhaustion.

Evaluation has a configurable step budget. This is not a CPU or memory sandbox:
larger inputs and individual native operations can consume more resources.

If evaluation aborts to Ruby, active parameter bindings are restored. Arbitrary
Scheme `dynamic-wind` after-thunks are not run during host-abort cleanup: that
would permit unbounded code to continue after budget exhaustion. Normal Scheme
returns, handled exceptions, and continuation transfers still run those thunks.

## TODO

- Audit the implemented functions and remove unused ones with no realistic role
  in our agent workflows. Check internal dependencies before removal and document
  any intentional departures from R7RS-small.
