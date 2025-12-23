# Changelog

## [7.1.0](https://github.com/barsoom/attr_extras/releases/tag/v7.1.0)

- Make `static_facade` and `method_object` take a block for initalization.

## [7.0.0](https://github.com/barsoom/attr_extras/releases/tag/v7.0.0)

- Drop end-of-lifed Ruby 2.5 and 2.6.
- Don't share default value object instances. (We now do a shallow `dup`.) Thanks to [sammo1235](https://github.com/barsoom/attr_extras/pull/46)!

## [6.2.4](https://github.com/barsoom/attr_extras/releases/tag/v6.2.4)

- Fix keyword argument warnings with Ruby 2.7. Thanks to [Elliot Winkler](https://github.com/barsoom/attr_extras/pull/34)!

## [6.2.3](https://github.com/barsoom/attr_extras/releases/tag/v6.2.3)

- `attr_implement` error says "an 'ear()' method" instead of "a 'ear()' method", when the method starts with a likely vowel.

## [6.2.2](https://github.com/barsoom/attr_extras/releases/tag/v6.2.2)

- Fix warnings with Ruby 2.7. Thanks to [Juanito Fatas](https://github.com/barsoom/attr_extras/pull/31)!
- Fix deprecation warnings for Minitest 6. Thanks again to [Juanito Fatas](https://github.com/barsoom/attr_extras/pull/30)!

## [6.2.1](https://github.com/barsoom/attr_extras/releases/tag/v6.2.1)

* Bugfix with keyword argument defaults. Thanks to [Roman Dubrovsky](https://github.com/barsoom/attr_extras/pull/29)!

## [6.2.0](https://github.com/barsoom/attr_extras/releases/tag/v6.2.0)

* Another bugfix when passing hash values to positional arguments.

## [6.1.0](https://github.com/barsoom/attr_extras/releases/tag/v6.1.0)

* Bugfix when passing hash values to positional arguments.

## 6.0.0 (yanked)

* Default arguments! Thanks to [Ola K](https://github.com/lesin). For example: `pattr_initialize [:foo, bar: "default value"]`

## [5.2.0](https://github.com/barsoom/attr_extras/releases/tag/v5.2.0) and earlier

Please [see Git history](https://github.com/barsoom/attr_extras/releases).
