# Configuration

A lot of code in prism's repository is templated from a single configuration file, [config.yml](../config.yml). This file is used to generate the following files:

* `ext/prism/api_node.c` - for defining how to build Ruby objects for the nodes out of C structs
* `include/prism/ast.h` - for defining the C structs that represent the nodes
* `include/prism/diagnostic.h` - for defining the diagnostics
* `javascript/src/deserialize.js` - for defining how to deserialize the nodes in JavaScript
* `javascript/src/nodes.js` - for defining the nodes in JavaScript
* `java/org/prism/AbstractNodeVisitor.java` - for defining the visitor interface for the nodes in Java
* `java/org/prism/Loader.java` - for defining how to deserialize the nodes in Java
* `java/org/prism/Nodes.java` - for defining the nodes in Java
* `lib/prism/compiler.rb` - for defining the compiler for the nodes in Ruby
* `lib/prism/dispatcher.rb` - for defining the dispatch visitors for the nodes in Ruby
* `lib/prism/dot_visitor.rb` - for defining the dot visitor for the nodes in Ruby
* `lib/prism/dsl.rb` - for defining the DSL for the nodes in Ruby
* `lib/prism/inspect_visitor.rb` - for defining the `#inspect` methods on nodes in Ruby
* `lib/prism/mutation_compiler.rb` - for defining the mutation compiler for the nodes in Ruby
* `lib/prism/node.rb` - for defining the nodes in Ruby
* `lib/prism/reflection.rb` - for defining the reflection API in Ruby
* `lib/prism/serialize.rb` - for defining how to deserialize the nodes in Ruby
* `lib/prism/visitor.rb` - for defining the visitor interface for the nodes in Ruby
* `src/diagnostic.c` - for defining how to build diagnostics
* `src/node.c` - for defining how to free the nodes in C and calculate the size in memory in C
* `src/prettyprint.c` - for defining how to prettyprint the nodes in C
* `src/serialize.c` - for defining how to serialize the nodes in C
* `src/token_type.c` - for defining the names of the token types

Whenever the structure of the nodes changes, you can run `rake templates` to regenerate these files. Alternatively tasks like `rake test` should pick up on these changes automatically. Every file that is templated will include a comment at the top indicating that it was generated and that changes should be made to the template and not the generated file.

`config.yml` has a couple of top level fields, which we'll describe below.

## `tokens`

This is a list of tokens to be used by the lexer. It is shared here so that it can be templated out into both an enum and a function that is used for debugging that returns the name of the token.

Each token is expected to have a `name` key and a `comment` key (both as strings). Optionally they can have a `value` key (an integer) which is used to represent the value in the enum.

In C these tokens will be templated out with the prefix `PM_TOKEN_`. For example, if you have a `name` key with the value `PERCENT`, you can access this in C through `PM_TOKEN_PERCENT`.

## `flags`

Sometimes we need to communicate more information in the tree than can be represented by the types of the nodes themselves. For example, we need to represent the flags passed to a regular expression or the type of call that a call node is performing. In these circumstances, it's helpful to reference a bitset of flags. This field is a list of flags that can be used in the nodes.

Each flag is expected to have a `name` key (a string) and a `values` key (an array). Each value in the `values` key should be an object that contains both a `name` key (a string) that represents the name of the flag and a `comment` key (a string) that represents the comment for the flag.

In C these flags will get templated out with a `PM_` prefix, then a snake-case version of the flag name, then the flag itself. For example, if you have a flag with the name `RegularExpressionFlags` and a value with the name `IGNORE_CASE`, you can access this in C through `PM_REGULAR_EXPRESSION_FLAGS_IGNORE_CASE`.

## `nodes`

Every node in the tree is defined in `config.yml`. Each node is expected to have a `name` key (a string) and a `comment` key (a string). By convention, the `comment` key uses the multi-line syntax of `: |` because the newlines will get templated into the comments of various files.

Optionally, every node can define a `child_nodes` key that is an array. This array represents each part of the node that isn't communicated through the type and location of the node itself. Within the `child_nodes` key, each entry should be an object with a `name` key (a string) and a `type` key (a string). The `name` key represents the name of the child node and the `type` is used to determine how it should be represented in each language.

The available values for `type` are:

* `node` - A field that is a node. This is a `pm_node_t *` in C.
* `node?` - A field that is a node that is optionally present. This is also a `pm_node_t *` in C, but can be `NULL`.
* `node[]` - A field that is an array of nodes. This is a `pm_node_list_t` in C.
* `string` - A field that is a string. For example, this is used as the name of the method in a call node, since it cannot directly reference the source string (as in `@-` or `foo=`). This is a `pm_string_t` in C.
* `constant` - A field that is an integer that represents an index in the constant pool. This is a `pm_constant_id_t` in C.
* `constant[]` - A field that is an array of constants. This is a `pm_constant_id_list_t` in C.
* `location` - A field that is a location. This is a `pm_location_t` in C.
* `location?` - A field that is a location that is optionally present. This is a `pm_location_t` in C, but if the value is not present then the `start` and `end` fields will be `NULL`.
* `uint8` - A field that is an 8-bit unsigned integer. This is a `uint8_t` in C.
* `uint32` - A field that is a 32-bit unsigned integer. This is a `uint32_t` in C.

If the type is `node` or `node?` then the value also accepts an optional `kind` key (a string). This key is expected to match to the name of another node type within `config.yml`. This changes a couple of places where code is templated out to use the more specific struct name instead of the generic `pm_node_t`. For example, with `kind: StatementsNode` the `pm_node_t *` in C becomes a `pm_statements_node_t *`.
