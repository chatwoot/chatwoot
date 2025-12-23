# Serialization

Prism ships with the ability to serialize a syntax tree to a single string.
The string can then be deserialized back into a syntax tree using a language other than C.
This is useful for using the parsing logic in other tools without having to write a parser in that language.
The syntax tree still requires a copy of the original source, as for the most part it just contains byte offsets into the source string.

## Types

Let us define some simple types for readability.

### varuint

A variable-length unsigned integer with the value fitting in `uint32_t` using between 1 and 5 bytes, using the [LEB128](https://en.wikipedia.org/wiki/LEB128) encoding.
This drastically cuts down on the size of the serialized string, especially when the source file is large.

### varsint

A variable-length signed integer with the value fitting in `int32_t` using between 1 and 5 bytes, using [ZigZag encoding](https://protobuf.dev/programming-guides/encoding/#signed-ints) into [LEB128].

### string

| # bytes | field |
| --- | --- |
| varuint | the length of the string in bytes |
| ... | the string bytes |

### location

| # bytes | field |
| --- | --- |
| varuint | byte offset into the source string where this location begins |
| varuint | length of the location in bytes in the source string |

### comment

The comment type is one of:

* 0=`INLINE` (`# comment`)
* 1=`EMBEDDED_DOCUMENT` (`=begin`/`=end`)

| # bytes | field |
| --- | --- |
| `1` | comment type |
| location | the location in the source of this comment |

### magic comment

| # bytes | field |
| --- | --- |
| location | the location of the key of the magic comment |
| location | the location of the value of the magic comment |

### error

| # bytes | field |
| --- | --- |
| varuint | type |
| string | error message (ASCII-only characters) |
| location | the location in the source this error applies to |
| `1` | the level of the error: `0` for `fatal`, `1` for `argument`, `2` for `load` |

### warning

| # bytes | field |
| --- | --- |
| varuint | type |
| string | warning message (ASCII-only characters) |
| location | the location in the source this warning applies to |
| `1` | the level of the warning: `0` for `default` and `1` for `verbose` |

### integer

| # bytes | field |
| --- | --- |
| `1` | `1` if the integer is negative, `0` if the integer is positive |
| varuint | the number of words in this integer |
| varuint+ | the words of the integer, least-significant to most-significant |

## Structure

The serialized string representing the syntax tree is composed of three parts: the header, the body, and the constant pool.
The header contains information like the version of prism that serialized the tree.
The body contains the actual nodes in the tree.
The constant pool contains constants that were interned while parsing.

The header is structured like the following table:

| # bytes | field |
| --- | --- |
| `5` | "PRISM" |
| `1` | major version number |
| `1` | minor version number |
| `1` | patch version number |
| `1` | 1 indicates only semantics fields were serialized, 0 indicates all fields were serialized (including location fields) |
| string | the encoding name |
| varsint | the start line |
| varuint | number of newline offsets |
| varuint* | newline offsets |
| varuint | number of comments |
| comment* | comments |
| varuint | number of magic comments |
| magic comment* | magic comments |
| location? | the optional location of the `__END__` keyword and its contents |
| varuint | number of errors |
| error* | errors |
| varuint | number of warnings |
| warning* | warnings |
| `4` | content pool offset |
| varuint | content pool size |

After the header comes the body of the serialized string.
The body consists of a sequence of nodes that is built using a prefix traversal order of the syntax tree.
Each node is structured like the following table:

| # bytes | field |
| --- | --- |
| `1` | node type |
| varuint | node identifier |
| location | node location |
| varuint | node flags |

Every field on the node is then appended to the serialized string. The fields can be determined by referencing `config.yml`. Depending on the type of field, it could take a couple of different forms, described below:

* `double` - A field that is a `double`. This is structured as a sequence of 8 bytes in native endian order.
* `node` - A field that is a node. This is structured just as like parent node.
* `node?` - A field that is a node that is optionally present. If the node is not present, then a single `0` byte will be written in its place. If it is present, then it will be structured just as like parent node.
* `node[]` - A field that is an array of nodes. This is structured as a variable-length integer length, followed by the child nodes themselves.
* `string` - A field that is a string. For example, this is used as the name of the method in a call node, since it cannot directly reference the source string (as in `@-` or `foo=`). This is structured as a variable-length integer byte length, followed by the string itself (_without_ a trailing null byte).
* `constant` - A variable-length integer that represents an index in the constant pool.
* `constant?` - An optional variable-length integer that represents an index in the constant pool. If it's not present, then a single `0` byte will be written in its place.
* `integer` - A field that represents an arbitrary-sized integer. The structure is listed above.
* `location` - A field that is a location. This is structured as a variable-length integer start followed by a variable-length integer length.
* `location?` - A field that is a location that is optionally present. If the location is not present, then a single `0` byte will be written in its place. If it is present, then it will be structured just like the `location` child node.
* `uint8` - A field that is an 8-bit unsigned integer. This is structured as a single byte.
* `uint32` - A field that is a 32-bit unsigned integer. This is structured as a variable-length integer.

After the syntax tree, the content pool is serialized. This is a list of constants that were referenced from within the tree. The content pool begins at the offset specified in the header. Constants can be either "owned" (in which case their contents are embedded in the serialization) or "shared" (in which case their contents represent a slice of the source string). The most significant bit of the constant indicates whether it is owned or shared.

In the case that it is owned, the constant is structured as follows:

| # bytes | field |
| --- | --- |
| `4` | the byte offset in the serialization for the contents of the constant |
| `4` | the byte length in the serialization |

Note that you will need to mask off the most significant bit for the byte offset in the serialization. In the case that it is shared, the constant is structured as follows:

| # bytes | field |
| --- | --- |
| `4` | the byte offset in the source string for the contents of the constant |
| `4` | the byte length in the source string |

After the constant pool, the contents of the owned constants are serialized. This is just a sequence of bytes that represent the contents of the constants. At the end of the serialization, the buffer is null terminated.

## APIs

The relevant APIs and struct definitions are listed below:

```c
// A pm_buffer_t is a simple memory buffer that stores data in a contiguous
// block of memory. It is used to store the serialized representation of a
// prism tree.
typedef struct {
  char *value;
  size_t length;
  size_t capacity;
} pm_buffer_t;

// Free the memory associated with the buffer.
void pm_buffer_free(pm_buffer_t *);

// Parse and serialize the AST represented by the given source to the given
// buffer.
void pm_serialize_parse(pm_buffer_t *buffer, const uint8_t *source, size_t length, const char *data);
```

Typically you would use a stack-allocated `pm_buffer_t` and call `pm_serialize_parse`, as in:

```c
void
serialize(const uint8_t *source, size_t length) {
  pm_buffer_t buffer = { 0 };
  pm_serialize_parse(&buffer, source, length, NULL);

  // Do something with the serialized string.

  pm_buffer_free(&buffer);
}
```

The final argument to `pm_serialize_parse` is an optional string that controls the options to the parse function. This includes all of the normal options that could be passed to `pm_parser_init` through a `pm_options_t` struct, but serialized as a string to make it easier for callers through FFI. Note that no `varuint` are used here to make it easier to produce the data for the caller, and also serialized size is less important here. The format of the data is structured as follows:

| # bytes | field                      |
| ------- | -------------------------- |
| `4`     | the length of the filepath |
| ...     | the filepath bytes         |
| `4`     | the line number            |
| `4`     | the length the encoding    |
| ...     | the encoding bytes         |
| `1`     | frozen string literal      |
| `1`     | command line flags         |
| `1`     | syntax version, see [pm_options_version_t](https://github.com/ruby/prism/blob/main/include/prism/options.h) for valid values |
| `1`     | whether or not the encoding is locked (should almost always be false) |
| `4`     | the number of scopes       |
| ...     | the scopes                 |

Command line flags are a bitset. By default every flag is `0`. It includes the following values:

* `0x1` - the `-a` option
* `0x2` - the `-e` option
* `0x4` - the `-l` option
* `0x8` - the `-n` option
* `0x10` - the `-p` option
* `0x20` - the `-x` option

Scopes are ordered from the outermost scope to the innermost one.

Each scope is laid out as follows:

| # bytes | field                      |
| ------- | -------------------------- |
| `4`     | the number of locals       |
| ...     | the locals                 |

Each local is laid out as follows:

| # bytes | field                      |
| ------- | -------------------------- |
| `4`     | the length of the local    |
| ...     | the local bytes            |

The data can be `NULL` (as seen in the example above).
