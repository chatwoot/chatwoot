---
title: Extending Administrate
---

Apart from the configuration described in these pages, it is possible to
extend Administrate's capabilities with the use of plugins. There are a
number of plugins available, many of which can be found at [RubyGems.org].
These are some popular examples:

1. [ActiveStorage support](https://github.com/Dreamersoul/administrate-field-active_storage)
2. [Enum field](https://github.com/Valiot/administrate-field-enum)
3. [Nested has-many forms](https://github.com/nickcharlton/administrate-field-nested_has_many)
4. [Belongs-to with Ajax search](https://github.com/fishbrain/administrate-field-belongs_to_search)
5. [JSONb field plugin for Administrate](https://github.com/codica2/administrate-field-jsonb/)

See many more at https://rubygems.org/gems/administrate/reverse_dependencies.

Please note that these plugins are written by third parties. We do not
have any control over them, and we cannot give any assurances as to how
well they perform their advertised functions.

You can write your own plugins too! We don't document this specifically,
but you can have a look at the existing plugins for some directions.
In general, Administrate tries to abide by Rails's conventions, so that
hopefully should help!

[RubyGems.org]: https://rubygems.org
