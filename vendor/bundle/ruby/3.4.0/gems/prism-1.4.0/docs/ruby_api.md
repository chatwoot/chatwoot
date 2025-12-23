# Ruby API

The `prism` gem provides a Ruby API for accessing the syntax tree.

For the most part, the API for accessing the tree mirrors that found in the [Syntax Tree](https://github.com/ruby-syntax-tree/syntax_tree) project. This means:

* Walking the tree involves creating a visitor and passing it to the `#accept` method on any node in the tree
* Nodes in the tree respond to named methods for accessing their children as well as `#child_nodes`
* Nodes respond to the pattern matching interfaces `#deconstruct` and `#deconstruct_keys`

Every entry in `config.yml` will generate a Ruby class as well as the code that builds the nodes themselves.
Creating a syntax tree involves calling one of the class methods on the `Prism` module.
The full API is documented below.

## API

* `Prism.dump(source)` - parse the syntax tree corresponding to the given source string, and serialize it to a string
* `Prism.dump_file(filepath)` - parse the syntax tree corresponding to the given source file and serialize it to a string
* `Prism.lex(source)` - parse the tokens corresponding to the given source string and return them as an array within a parse result
* `Prism.lex_file(filepath)` - parse the tokens corresponding to the given source file and return them as an array within a parse result
* `Prism.parse(source)` - parse the syntax tree corresponding to the given source string and return it within a parse result
* `Prism.parse_file(filepath)` - parse the syntax tree corresponding to the given source file and return it within a parse result
* `Prism.parse_stream(io)` - parse the syntax tree corresponding to the source that is read out of the given IO object using the `#gets` method and return it within a parse result
* `Prism.parse_lex(source)` - parse the syntax tree corresponding to the given source string and return it within a parse result, along with the tokens
* `Prism.parse_lex_file(filepath)` - parse the syntax tree corresponding to the given source file and return it within a parse result, along with the tokens
* `Prism.load(source, serialized, freeze = false)` - load the serialized syntax tree using the source as a reference into a syntax tree
* `Prism.parse_comments(source)` - parse the comments corresponding to the given source string and return them
* `Prism.parse_file_comments(source)` - parse the comments corresponding to the given source file and return them
* `Prism.parse_success?(source)` - parse the syntax tree corresponding to the given source string and return true if it was parsed without errors
* `Prism.parse_file_success?(filepath)` - parse the syntax tree corresponding to the given source file and return true if it was parsed without errors

## Nodes

Once you have nodes in hand coming out of a parse result, there are a number of common APIs that are available on each instance. They are:

* `#accept(visitor)` - a method that will immediately call `visit_*` to specialize for the node type
* `#child_nodes` - a positional array of the child nodes of the node, with `nil` values for any missing children
* `#compact_child_nodes` - a positional array of the child nodes of the node with no `nil` values
* `#copy(**keys)` - a method that allows creating a shallow copy of the node with the given keys overridden
* `#deconstruct`/`#deconstruct_keys(keys)` - the pattern matching interface for nodes
* `#inspect` - a string representation that looks like the syntax tree of the node
* `#location` - a `Location` object that describes the location of the node in the source file
* `#to_dot` - convert the node's syntax tree into graphviz dot notation
* `#type` - a symbol that represents the type of the node, useful for quick comparisons
