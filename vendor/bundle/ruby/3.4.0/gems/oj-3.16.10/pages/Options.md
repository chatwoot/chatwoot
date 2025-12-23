# Oj Options

To change default serialization mode use the following form. Attempting to
modify the Oj.default_options Hash directly will not set the changes on the
actual default options but on a copy of the Hash:

```ruby
Oj.default_options = {:mode => :compat }
```

Another way to make use of options when calling load or dump methods is to
pass in a Hash with the options already set in the Hash. This is slightly less
efficient than setting the globals for many smaller JSON documents but does
provide a more thread safe approach to using custom options for loading and
dumping.

### Options for serializer and parser

### :allow_blank [Boolean]

If true a nil input to load will return nil and not raise an Exception.

### :allow_gc [Boolean]

Allow or prohibit GC during parsing, default is true (allow).

### :allow_invalid_unicode [Boolean]

Allow invalid unicode, default is false (don't allow).

### :allow_nan

Alias for the :nan option.

### :array_class [Class]

Class to use instead of Array on load.

### :array_nl

Trailer appended to the end of an array dump. The default is an empty
string. Primarily intended for json gem compatibility. Using just indent as an
integer gives better performance.

### :ascii_only

If true all non-ASCII character are escaped when dumping. This is the same as
setting the :escape_mode options to :ascii and exists for json gem
compatibility.

### :auto_define [Boolean]

Automatically define classes if they do not exist.

### :bigdecimal_as_decimal [Boolean]

If true dump BigDecimal as a decimal number otherwise as a String

### :bigdecimal_load [Symbol]

Determines how to load decimals.

 - `:bigdecimal` convert all decimal numbers to BigDecimal.

 - `:float` convert all decimal numbers to Float.

 - `:auto` the most precise for the number of digits is used.

 - `:fast` faster conversion to Float.

 - `:ruby` convert to Float using the Ruby `to_f` conversion.

This can also be set with `:decimal_class` when used as a load or
parse option to match the JSON gem. In that case either `Float`,
`BigDecimal`, or `nil` can be provided.

### :cache_keys [Boolean]

If true Hash keys are cached or interned. There are trade-offs with
caching keys. Large caches will use more memory and in extreme cases
(like over a million) the cache may be slower than not using
it. Repeated parsing of similar JSON docs is where cache_keys shines
especially with symbol keys.

There is a maximum length for cached keys. Any key longer than 34
bytes is not cached. Everything still works but the key is not cached.

### :cache_strings [Int]

Shorter strings can be cached for better performance. A limit,
cache_strings, defines the upper limit on what strings are cached. As
with cached keys only strings less than 35 bytes are cached even if
the limit is set higher. Setting the limit to zero effectively
disables the caching of string values.

Note that caching for strings is for string values and not Hash keys
or Object attributes.

### :circular [Boolean]

Detect circular references while dumping. In :compat mode raise a
NestingError. For other modes except the :object mode place a null in the
output. For :object mode place references in the output that will be used to
recreate the looped references on load.

### :class_cache [Boolean]

Cache classes for faster parsing. This option should not be used if
dynamically modifying classes or reloading classes then don't use this.

### :compat_bigdecimal [Boolean]

Determines how to load decimals when in `:compat` mode.

 - `true` convert all decimal numbers to BigDecimal.

 - `false` convert all decimal numbers to Float.

### :create_additions

A flag indicating that the :create_id key, when encountered during parsing,
should create an Object matching the class name specified in the value
associated with the key.

### :create_id [String]

The :create_id option specifies that key is used for dumping and loading when
specifying the class for an encoded object. The default is `json_create`.

In the `:custom` mode, setting the `:create_id` to nil will cause Complex,
Rational, Range, and Regexp to be output as strings instead of as JSON
objects.

### :empty_string [Boolean]

If true an empty or all whitespace input will not raise an Exception. The
default_options will be honored for :null, :strict, and :custom modes. Ignored
for :custom and :wab. The :compat has a more complex set of rules. The JSON
gem compatibility is best described by examples.

```
JSON.parse('') => raise
JSON.parse(' ') => raise
JSON.load('') => nil
JSON.load('', nil, allow_blank: false) => raise
JSON.load('', nil, allow_blank: true) => nil
JSON.load(' ') => raise
JSON.load(' ', nil, allow_blank: false) => raise
JSON.load(' ', nil, allow_blank: true) => raise
```

### :escape_mode [Symbol]

Determines the characters to escape when dumping. Only the :ascii and
:json modes are supported in :compat mode.

 - `:newline` allows unescaped newlines in the output.

 - `:json` follows the JSON specification. This is the default mode.

 - `:slash` escapes `/` characters.

 - `:xss_safe` escapes HTML and XML characters such as `&` and `<`.

 - `:ascii` escapes all non-ascii or characters with the hi-bit set.

 - `:unicode_xss` escapes a special unicodes and is xss safe.

### :float_precision [Fixnum]

The number of digits of precision when dumping floats, 0 indicates use Ruby directly.

### :hash_class [Class]

Class to use instead of Hash on load. This is the same as the :object_class.

### :ignore [Array]

Ignore all the classes in the Array when dumping. A value of nil indicates
ignore nothing.

### :indent [Fixnum]

Number of spaces to indent each element in a JSON document, zero is no newline
between JSON elements, negative indicates no newline between top level JSON
elements in a stream.

### :indent_str

Indentation for each element when dumping. The default is an empty
string. Primarily intended for json gem compatibility. Using just indent as an
integer gives better performance.

### :integer_range [Range]

Dump integers outside range as strings.
Note: range bounds must be Fixnum.

### :match_string

Provides a means to detect strings that should be used to create non-String
objects. The value to the option must be a Hash with keys that are regular
expressions and values are class names. For strict json gem compatibility a
RegExp should be used. For better performance but sacrificing some regexp
options a string can be used and the C version of regex will be used instead.

### :max_nesting

The maximum nesting depth on both dump and load that is allowed. This exists
for json gem compatibility.

### :mode [Symbol]

Primary behavior for loading and dumping. The :mode option controls which
other options are in effect. For more details see the {file:Modes.md} page. By
default Oj uses the :custom mode which is provides the highest degree of
customization.

### :nan [Symbol]

How to dump Infinity, -Infinity, and NaN in :null, :strict, and :compat
mode. Default is :auto but is ignored in the :compat and :rails modes.

 - `:null` places a null

 - `:huge` places a huge number

 - `:word` places Infinity or NaN

 - `:raise` raises and exception

 - `:auto` uses default for each mode which are `:raise` for `:strict`, `:null` for `:null`, and `:word` for `:compat`.

### :nilnil [Boolean]

If true a nil input to load will return nil and not raise an Exception.

### :object_class

The class to use when creating a Hash on load instead of the Hash class.

### :object_nl

Trailer appended to the end of an object dump. The default is an empty
string. Primarily intended for json gem compatibility. Using just indent as an
integer gives better performance.

### :omit_nil [Boolean]

If true, Hash and Object attributes with nil values are omitted.

### :quirks_mode [Boolean]

Allow single JSON values instead of documents, default is true (allow). This
can also be used in :compat mode to be backward compatible with older versions
of the json gem.

### :safe

The JSON gem includes the complete JSON in parse errors with no limit
on size. To break from the JSON gem behavior for this case set `:safe`
to true.

### :second_precision [Fixnum]

The number of digits after the decimal when dumping the seconds of time.

### :skip_null_byte [Boolean]

If true, null bytes in strings will be omitted when dumping.

### :space

String inserted after the ':' character when dumping a JSON object. The
default is an empty string. Primarily intended for json gem
compatibility. Using just indent as an integer gives better performance.

### :space_before

String inserted before the ':' character when dumping a JSON object. The
default is an empty string. Primarily intended for json gem
compatibility. Using just indent as an integer gives better performance.

### :symbol_keys [Boolean]

Use symbols instead of strings for hash keys.

### :symbolize_names [Boolean]

Like :symbol_keys has keys are made into symbols but only when
mimicking the JSON gem and then only as the JSON gem honors it so
JSON.parse honors the option but JSON.load does not.

### :trace

When true dump and load functions are traced by printing beginning and ending
of blocks and of specific calls.

### :time_format [Symbol]

The :time_format when dumping.

 - `:unix` time is output as a decimal number in seconds since epoch including fractions of a second.

 - `:unix_zone` is similar to the `:unix` format but with the timezone encoded in
   the exponent of the decimal number of seconds since epoch.

 - `:xmlschema` time is output as a string that follows the XML schema definition.

 - `:ruby` time is output as a string formatted using the Ruby `to_s` conversion.

### :use_as_json [Boolean]

Call `as_json()` methods on dump, default is false. The option is ignored in
the :compat and :rails modes.


### :use_raw_json [Boolean]

Call `raw_json()` methods on dump, default is false. The option is
accepted in the :compat and :rails modes even though it is not
supported by other JSON gems. It provides a means to optimize dump or
generate performance. The `raw_json(depth, indent)` method should be
called only by Oj. It is not intended for any other use. This is meant
to replace the abused `to_json` methods. Calling `Oj.dump` inside the
`raw_json` with the object itself when `:use_raw_json` is true will
result in an infinite loop.

### :use_to_hash [Boolean]

Call `to_hash()` methods on dump, default is false. The option is ignored in
the :compat and :rails modes.

### :use_to_json [Boolean]

Call `to_json()` methods on dump, default is false. The option is ignored in
the :compat and :rails modes.
