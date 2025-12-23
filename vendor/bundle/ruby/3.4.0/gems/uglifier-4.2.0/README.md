# Uglifier

Ruby wrapper for [UglifyJS](https://github.com/mishoo/UglifyJS2) JavaScript
compressor.

UglifyJS currently is extensively tested with ES5, but also includes experimental ES6/ES2015+/Harmony support.

More stable alternatives for working with ES6 code is to first transpile to ES5 with e.g. [babel-transpiler](https://github.com/babel/ruby-babel-transpiler) or using [Closure Compiler](https://github.com/documentcloud/closure-compiler) to directly minify ES6 code.

[![Build Status](https://travis-ci.org/lautis/uglifier.svg?branch=master)](https://travis-ci.org/lautis/uglifier)

## ES6 / ES2015+ / Harmony mode

When using Uglifier with ES6 syntax without any options, an error will be
thrown.

```
Uglifier::Error: Unexpected token: punc ((). To use ES6 syntax, harmony mode must be enabled with Uglifier.new(:harmony => true).
```

The experimental ES6 syntax support can be enabled by passing `:harmony => true`
option to Uglifier.

```ruby
Uglifier.compile(js, harmony: true)
```

### Rails

When used in Rails, replace

```ruby
config.assets.js_compressor = :uglifier
```

with

```ruby
config.assets.js_compressor = Uglifier.new(harmony: true)
```

in `config/environments/production.rb`.

## Installation

Uglifier is available as a ruby gem.

    $ gem install uglifier

Ensure that your environment has a JavaScript interpreter supported by
[ExecJS](https://github.com/sstephenson/execjs). Using `therubyracer` gem
is a safe choice if a runtime isn't already present. Note that while JScript built-in Windows 7 and older works, it is extremely slow.

## Usage

```ruby
require 'uglifier'

Uglifier.new.compile(File.read("source.js"))
# => js file minified

# Or alternatively
Uglifier.compile(File.read("source.js"))
```

Uglifier also supports generating source maps:

```ruby
uglified, source_map = Uglifier.new.compile_with_map(source)
```

When initializing UglifyJS, you can tune the behavior of UglifyJS by passing options. For example, if you want disable variable name mangling:

```ruby
Uglifier.new(:mangle => false).compile(source)

# Or
Uglifier.compile(source, :mangle => false)
```

Available options and their defaults are

```ruby
{
  :output => {
    :ascii_only => true,        # Escape non-ASCII characters
    :comments => :copyright,    # Preserve comments (:all, :jsdoc, :copyright, :none, Regexp (see below))
    :inline_script => false,    # Escape occurrences of </script in strings
    :quote_keys => false,       # Quote keys in object literals
    :max_line_len => 32 * 1024, # Maximum line length in minified code
    :bracketize => false,       # Bracketize if, for, do, while or with statements, even if their body is a single statement
    :semicolons => true,        # Separate statements with semicolons
    :preserve_line => false,    # Preserve line numbers in outputs
    :beautify => false,         # Beautify output
    :indent_level => 4,         # Indent level in spaces
    :indent_start => 0,         # Starting indent level
    :width => 80,               # Specify line width when beautifier is used (only with beautifier)
    :preamble => nil,           # Preamble for the generated JS file. Can be used to insert any code or comment.
    :wrap_iife => false         # Wrap IIFEs in parenthesis. Note: this disables the negate_iife compression option.
    :shebang => true            # Preserve shebang (#!) in preamble (shell scripts)
    :quote_style => 0,          # Quote style, possible values :auto (default), :single, :double, :original
    :keep_quoted_props => false # Keep quotes property names
  },
  :mangle => {
    :eval => false,             # Mangle names when eval of when is used in scope
    :reserved => ["$super"],    # Argument names to be excluded from mangling
    :sort => false,             # Assign shorter names to most frequently used variables. Often results in bigger output after gzip.
    :toplevel => false,         # Mangle names declared in the toplevel scope
    :properties => false,       # Mangle property names
    :keep_fnames => false       # Do not modify function names
  },                            # Mangle variable and function names, set to false to skip mangling
  :mangle_properties => {
    :regex => nil,              # A regular expression to filter property names to be mangled
    :ignore_quoted => false,    # Only mangle unquoted property names
    :debug => false,            # Mangle names with the original name still present
  }                             # Mangle property names, disabled by default
  :compress => {
    :sequences => true,         # Allow statements to be joined by commas
    :properties => true,        # Rewrite property access using the dot notation
    :dead_code => true,         # Remove unreachable code
    :drop_debugger => true,     # Remove debugger; statements
    :unsafe => false,           # Apply "unsafe" transformations
    :unsafe_comps => false,     # Reverse < and <= to > and >= to allow improved compression. This might be unsafe when an at least one of two operands is an object with computed values due the use of methods like get, or valueOf. This could cause change in execution order after operands in the comparison are switching. Compression only works if both comparisons and unsafe_comps are both set to true.
    :unsafe_math => false,      # Optimize numerical expressions like 2 * x * 3 into 6 * x, which may give imprecise floating point results.
    :unsafe_proto => false,     # Optimize expressions like Array.prototype.slice.call(a) into [].slice.call(a)
    :conditionals => true,      # Optimize for if-s and conditional expressions
    :comparisons => true,       # Apply binary node optimizations for comparisons
    :evaluate => true,          # Attempt to evaluate constant expressions
    :booleans => true,          # Various optimizations to boolean contexts
    :loops => true,             # Optimize loops when condition can be statically determined
    :unused => true,            # Drop unreferenced functions and variables
    :toplevel => false,         # Drop unreferenced top-level functions and variables
    :top_retain => [],          # prevent specific toplevel functions and variables from `unused` removal
    :hoist_funs => true,        # Hoist function declarations
    :hoist_vars => false,       # Hoist var declarations
    :if_return => true,         # Optimizations for if/return and if/continue
    :join_vars => true,         # Join consecutive var statements
    :collapse_vars => false,    # Collapse single-use var and const definitions when possible.
    :reduce_funcs => false,     # Inline single-use functions as function expressions. Depends on reduce_vars.
    :reduce_vars => false,      # Collapse variables assigned with and used as constant values.
    :negate_iife => true,       # Negate immediately invoked function expressions to avoid extra parens
    :pure_getters => false,     # Assume that object property access does not have any side-effects
    :pure_funcs => nil,         # List of functions without side-effects. Can safely discard function calls when the result value is not used
    :drop_console => false,     # Drop calls to console.* functions
    :keep_fargs => false,       # Preserve unused function arguments
    :keep_fnames => false,      # Do not drop names in function definitions
    :passes => 1,               # Number of times to run compress. Raising the number of passes will increase compress time, but can produce slightly smaller code.
    :keep_infinity => false,    # Prevent compression of Infinity to 1/0
    :side_effects => true,      # Pass false to disable potentially dropping functions marked as "pure" using pure comment annotation. See UglifyJS documentation for details.
    :switches => true,          # de-duplicate and remove unreachable switch branches
  },                            # Apply transformations to code, set to false to skip
  :parse => {
    :bare_returns => false,     # Allow top-level return statements.
    :expression => false,       # Parse a single expression, rather than a program (for parsing JSON).
    :html5_comments => true,    # Ignore HTML5 comments in input
    :shebang => true,           # support #!command as the first line
    :strict => false
  },
  :define => {},                # Define values for symbol replacement
  :enclose => false,            # Enclose in output function wrapper, define replacements as key-value pairs
  :keep_fnames => false,        # Generate code safe for the poor souls relying on Function.prototype.name at run-time. Sets both compress and mangle keep_fanems to true.
  :source_map => {
    :map_url => false,          # Url for source mapping to be appended in minified source
    :url => false,              # Url for original source to be appended in minified source
    :sources_content => false,  # Include original source content in map
    :filename => nil,           # The filename of the input file
    :root => nil,               # The URL of the directory which contains :filename
    :output_filename => nil,    # The filename or URL where the minified output can be found
    :input_source_map => nil    # The contents of the source map describing the input
  },
  :error_context_lines => 8,    # How many context lines surrounding the error line. Env var ERROR_CONTEXT_LINES overrides this option
  :harmony => false             # Enable ES6/Harmony mode (experimental). Disabling mangling and compressing is recommended with Harmony mode.
}
```

When passing a regular expression to the output => comments option, be sure to pass a valid Ruby Regexp.
The beginning and ending of comments are removed and cannot be matched (/*, */, //). For example:
When matching

```
/*!
 * comment
 */
```

use `Uglifier.new(output: {comments: /^!/})`.

## Development

Tests are run using

    bundle exec rake

See [CONTRIBUTING](https://github.com/lautis/uglifier/blob/master/CONTRIBUTING.md) for details about working on and contributing to Uglifier.

## Copyright

© Ville Lautanala. Released under MIT license, see [LICENSE](https://github.com/lautis/uglifier/blob/master/LICENSE.txt) for details.
