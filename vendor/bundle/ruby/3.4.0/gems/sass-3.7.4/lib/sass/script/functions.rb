require 'sass/script/value/helpers'

module Sass::Script
  #   YARD can't handle some multiline tags, and we need really long tags for function declarations.
  # Methods in this module are accessible from the SassScript context.
  # For example, you can write
  #
  #     $color: hsl(120deg, 100%, 50%)
  #
  # and it will call {Functions#hsl}.
  #
  # The following functions are provided:
  #
  # *Note: These functions are described in more detail below.*
  #
  # ## RGB Functions
  #
  # \{#rgb rgb($red, $green, $blue)}
  # : Creates a {Sass::Script::Value::Color Color} from red, green, and blue
  #   values.
  #
  # \{#rgba rgba($red, $green, $blue, $alpha)}
  # : Creates a {Sass::Script::Value::Color Color} from red, green, blue, and
  #   alpha values.
  #
  # \{#red red($color)}
  # : Gets the red component of a color.
  #
  # \{#green green($color)}
  # : Gets the green component of a color.
  #
  # \{#blue blue($color)}
  # : Gets the blue component of a color.
  #
  # \{#mix mix($color1, $color2, \[$weight\])}
  # : Mixes two colors together.
  #
  # ## HSL Functions
  #
  # \{#hsl hsl($hue, $saturation, $lightness)}
  # : Creates a {Sass::Script::Value::Color Color} from hue, saturation, and
  #   lightness values.
  #
  # \{#hsla hsla($hue, $saturation, $lightness, $alpha)}
  # : Creates a {Sass::Script::Value::Color Color} from hue, saturation,
  #   lightness, and alpha values.
  #
  # \{#hue hue($color)}
  # : Gets the hue component of a color.
  #
  # \{#saturation saturation($color)}
  # : Gets the saturation component of a color.
  #
  # \{#lightness lightness($color)}
  # : Gets the lightness component of a color.
  #
  # \{#adjust_hue adjust-hue($color, $degrees)}
  # : Changes the hue of a color.
  #
  # \{#lighten lighten($color, $amount)}
  # : Makes a color lighter.
  #
  # \{#darken darken($color, $amount)}
  # : Makes a color darker.
  #
  # \{#saturate saturate($color, $amount)}
  # : Makes a color more saturated.
  #
  # \{#desaturate desaturate($color, $amount)}
  # : Makes a color less saturated.
  #
  # \{#grayscale grayscale($color)}
  # : Converts a color to grayscale.
  #
  # \{#complement complement($color)}
  # : Returns the complement of a color.
  #
  # \{#invert invert($color, \[$weight\])}
  # : Returns the inverse of a color.
  #
  # ## Opacity Functions
  #
  # \{#alpha alpha($color)} / \{#opacity opacity($color)}
  # : Gets the alpha component (opacity) of a color.
  #
  # \{#rgba rgba($color, $alpha)}
  # : Changes the alpha component for a color.
  #
  # \{#opacify opacify($color, $amount)} / \{#fade_in fade-in($color, $amount)}
  # : Makes a color more opaque.
  #
  # \{#transparentize transparentize($color, $amount)} / \{#fade_out fade-out($color, $amount)}
  # : Makes a color more transparent.
  #
  # ## Other Color Functions
  #
  # \{#adjust_color adjust-color($color, \[$red\], \[$green\], \[$blue\], \[$hue\], \[$saturation\], \[$lightness\], \[$alpha\])}
  # : Increases or decreases one or more components of a color.
  #
  # \{#scale_color scale-color($color, \[$red\], \[$green\], \[$blue\], \[$saturation\], \[$lightness\], \[$alpha\])}
  # : Fluidly scales one or more properties of a color.
  #
  # \{#change_color change-color($color, \[$red\], \[$green\], \[$blue\], \[$hue\], \[$saturation\], \[$lightness\], \[$alpha\])}
  # : Changes one or more properties of a color.
  #
  # \{#ie_hex_str ie-hex-str($color)}
  # : Converts a color into the format understood by IE filters.
  #
  # ## String Functions
  #
  # \{#unquote unquote($string)}
  # : Removes quotes from a string.
  #
  # \{#quote quote($string)}
  # : Adds quotes to a string.
  #
  # \{#str_length str-length($string)}
  # : Returns the number of characters in a string.
  #
  # \{#str_insert str-insert($string, $insert, $index)}
  # : Inserts `$insert` into `$string` at `$index`.
  #
  # \{#str_index str-index($string, $substring)}
  # : Returns the index of the first occurrence of `$substring` in `$string`.
  #
  # \{#str_slice str-slice($string, $start-at, [$end-at])}
  # : Extracts a substring from `$string`.
  #
  # \{#to_upper_case to-upper-case($string)}
  # : Converts a string to upper case.
  #
  # \{#to_lower_case to-lower-case($string)}
  # : Converts a string to lower case.
  #
  # ## Number Functions
  #
  # \{#percentage percentage($number)}
  # : Converts a unitless number to a percentage.
  #
  # \{#round round($number)}
  # : Rounds a number to the nearest whole number.
  #
  # \{#ceil ceil($number)}
  # : Rounds a number up to the next whole number.
  #
  # \{#floor floor($number)}
  # : Rounds a number down to the previous whole number.
  #
  # \{#abs abs($number)}
  # : Returns the absolute value of a number.
  #
  # \{#min min($numbers...)\}
  # : Finds the minimum of several numbers.
  #
  # \{#max max($numbers...)\}
  # : Finds the maximum of several numbers.
  #
  # \{#random random([$limit])\}
  # : Returns a random number.
  #
  # ## List Functions {#list-functions}
  #
  # Lists in Sass are immutable; all list functions return a new list rather
  # than updating the existing list in-place.
  #
  # All list functions work for maps as well, treating them as lists of pairs.
  #
  # \{#length length($list)}
  # : Returns the length of a list.
  #
  # \{#nth nth($list, $n)}
  # : Returns a specific item in a list.
  #
  # \{#set-nth set-nth($list, $n, $value)}
  # : Replaces the nth item in a list.
  #
  # \{#join join($list1, $list2, \[$separator, $bracketed\])}
  # : Joins together two lists into one.
  #
  # \{#append append($list1, $val, \[$separator\])}
  # : Appends a single value onto the end of a list.
  #
  # \{#zip zip($lists...)}
  # : Combines several lists into a single multidimensional list.
  #
  # \{#index index($list, $value)}
  # : Returns the position of a value within a list.
  #
  # \{#list_separator list-separator($list)}
  # : Returns the separator of a list.
  #
  # \{#is_bracketed is-bracketed($list)}
  # : Returns whether a list has square brackets.
  #
  # ## Map Functions {#map-functions}
  #
  # Maps in Sass are immutable; all map functions return a new map rather than
  # updating the existing map in-place.
  #
  # \{#map_get map-get($map, $key)}
  # : Returns the value in a map associated with a given key.
  #
  # \{#map_merge map-merge($map1, $map2)}
  # : Merges two maps together into a new map.
  #
  # \{#map_remove map-remove($map, $keys...)}
  # : Returns a new map with keys removed.
  #
  # \{#map_keys map-keys($map)}
  # : Returns a list of all keys in a map.
  #
  # \{#map_values map-values($map)}
  # : Returns a list of all values in a map.
  #
  # \{#map_has_key map-has-key($map, $key)}
  # : Returns whether a map has a value associated with a given key.
  #
  # \{#keywords keywords($args)}
  # : Returns the keywords passed to a function that takes variable arguments.
  #
  # ## Selector Functions
  #
  # Selector functions are very liberal in the formats they support
  # for selector arguments. They can take a plain string, a list of
  # lists as returned by `&` or anything in between:
  #
  # * A plain string, such as `".foo .bar, .baz .bang"`.
  # * A space-separated list of strings such as `(".foo" ".bar")`.
  # * A comma-separated list of strings such as `(".foo .bar", ".baz .bang")`.
  # * A comma-separated list of space-separated lists of strings such
  #   as `((".foo" ".bar"), (".baz" ".bang"))`.
  #
  # In general, selector functions allow placeholder selectors
  # (`%foo`) but disallow parent-reference selectors (`&`).
  #
  # \{#selector_nest selector-nest($selectors...)}
  # : Nests selector beneath one another like they would be nested in the
  #   stylesheet.
  #
  # \{#selector_append selector-append($selectors...)}
  # : Appends selectors to one another without spaces in between.
  #
  # \{#selector_extend selector-extend($selector, $extendee, $extender)}
  # : Extends `$extendee` with `$extender` within `$selector`.
  #
  # \{#selector_replace selector-replace($selector, $original, $replacement)}
  # : Replaces `$original` with `$replacement` within `$selector`.
  #
  # \{#selector_unify selector-unify($selector1, $selector2)}
  # : Unifies two selectors to produce a selector that matches
  #   elements matched by both.
  #
  # \{#is_superselector is-superselector($super, $sub)}
  # : Returns whether `$super` matches all the elements `$sub` does, and
  #   possibly more.
  #
  # \{#simple_selectors simple-selectors($selector)}
  # : Returns the simple selectors that comprise a compound selector.
  #
  # \{#selector_parse selector-parse($selector)}
  # : Parses a selector into the format returned by `&`.
  #
  # ## Introspection Functions
  #
  # \{#feature_exists feature-exists($feature)}
  # : Returns whether a feature exists in the current Sass runtime.
  #
  # \{#variable_exists variable-exists($name)}
  # : Returns whether a variable with the given name exists in the current scope.
  #
  # \{#global_variable_exists global-variable-exists($name)}
  # : Returns whether a variable with the given name exists in the global scope.
  #
  # \{#function_exists function-exists($name)}
  # : Returns whether a function with the given name exists.
  #
  # \{#mixin_exists mixin-exists($name)}
  # : Returns whether a mixin with the given name exists.
  #
  # \{#content_exists content-exists()}
  # : Returns whether the current mixin was passed a content block.
  #
  # \{#inspect inspect($value)}
  # : Returns the string representation of a value as it would be represented in Sass.
  #
  # \{#type_of type-of($value)}
  # : Returns the type of a value.
  #
  # \{#unit unit($number)}
  # : Returns the unit(s) associated with a number.
  #
  # \{#unitless unitless($number)}
  # : Returns whether a number has units.
  #
  # \{#comparable comparable($number1, $number2)}
  # : Returns whether two numbers can be added, subtracted, or compared.
  #
  # \{#call call($function, $args...)}
  # : Dynamically calls a Sass function reference returned by `get-function`.
  #
  # \{#get_function get-function($name, $css: false)}
  # : Looks up a function with the given name in the current lexical scope
  #   and returns a reference to it.
  #
  # ## Miscellaneous Functions
  #
  # \{#if if($condition, $if-true, $if-false)}
  # : Returns one of two values, depending on whether or not `$condition` is
  #   true.
  #
  # \{#unique_id unique-id()}
  # : Returns a unique CSS identifier.
  #
  # ## Adding Custom Functions
  #
  # New Sass functions can be added by adding Ruby methods to this module.
  # For example:
  #
  #     module Sass::Script::Functions
  #       def reverse(string)
  #         assert_type string, :String
  #         Sass::Script::Value::String.new(string.value.reverse)
  #       end
  #       declare :reverse, [:string]
  #     end
  #
  # Calling {declare} tells Sass the argument names for your function.
  # If omitted, the function will still work, but will not be able to accept keyword arguments.
  # {declare} can also allow your function to take arbitrary keyword arguments.
  #
  # There are a few things to keep in mind when modifying this module.
  # First of all, the arguments passed are {Value} objects.
  # Value objects are also expected to be returned.
  # This means that Ruby values must be unwrapped and wrapped.
  #
  # Most Value objects support the {Value::Base#value value} accessor for getting
  # their Ruby values. Color objects, though, must be accessed using
  # {Sass::Script::Value::Color#rgb rgb}, {Sass::Script::Value::Color#red red},
  # {Sass::Script::Value::Color#blue green}, or {Sass::Script::Value::Color#blue
  # blue}.
  #
  # Second, making Ruby functions accessible from Sass introduces the temptation
  # to do things like database access within stylesheets.
  # This is generally a bad idea;
  # since Sass files are by default only compiled once,
  # dynamic code is not a great fit.
  #
  # If you really, really need to compile Sass on each request,
  # first make sure you have adequate caching set up.
  # Then you can use {Sass::Engine} to render the code,
  # using the {file:SASS_REFERENCE.md#custom-option `options` parameter}
  # to pass in data that {EvaluationContext#options can be accessed}
  # from your Sass functions.
  #
  # Within one of the functions in this module,
  # methods of {EvaluationContext} can be used.
  #
  # ### Caveats
  #
  # When creating new {Value} objects within functions, be aware that it's not
  # safe to call {Value::Base#to_s #to_s} (or other methods that use the string
  # representation) on those objects without first setting {Tree::Node#options=
  # the #options attribute}.
  #
  module Functions
    @signatures = {}

    # A class representing a Sass function signature.
    #
    # @attr args [Array<String>] The names of the arguments to the function.
    # @attr delayed_args [Array<String>] The names of the arguments whose evaluation should be
    #   delayed.
    # @attr var_args [Boolean] Whether the function takes a variable number of arguments.
    # @attr var_kwargs [Boolean] Whether the function takes an arbitrary set of keyword arguments.
    Signature = Struct.new(:args, :delayed_args, :var_args, :var_kwargs, :deprecated)

    # Declare a Sass signature for a Ruby-defined function.
    # This includes the names of the arguments,
    # whether the function takes a variable number of arguments,
    # and whether the function takes an arbitrary set of keyword arguments.
    #
    # It's not necessary to declare a signature for a function.
    # However, without a signature it won't support keyword arguments.
    #
    # A single function can have multiple signatures declared
    # as long as each one takes a different number of arguments.
    # It's also possible to declare multiple signatures
    # that all take the same number of arguments,
    # but none of them but the first will be used
    # unless the user uses keyword arguments.
    #
    # @example
    #   declare :rgba, [:hex, :alpha]
    #   declare :rgba, [:red, :green, :blue, :alpha]
    #   declare :accepts_anything, [], :var_args => true, :var_kwargs => true
    #   declare :some_func, [:foo, :bar, :baz], :var_kwargs => true
    #
    # @param method_name [Symbol] The name of the method
    #   whose signature is being declared.
    # @param args [Array<Symbol>] The names of the arguments for the function signature.
    # @option options :var_args [Boolean] (false)
    #   Whether the function accepts a variable number of (unnamed) arguments
    #   in addition to the named arguments.
    # @option options :var_kwargs [Boolean] (false)
    #   Whether the function accepts other keyword arguments
    #   in addition to those in `:args`.
    #   If this is true, the Ruby function will be passed a hash from strings
    #   to {Value}s as the last argument.
    #   In addition, if this is true and `:var_args` is not,
    #   Sass will ensure that the last argument passed is a hash.
    def self.declare(method_name, args, options = {})
      delayed_args = []
      args = args.map do |a|
        a = a.to_s
        if a[0] == ?&
          a = a[1..-1]
          delayed_args << a
        end
        a
      end
      # We don't expose this functionality except to certain builtin methods.
      if delayed_args.any? && method_name != :if
        raise ArgumentError.new("Delayed arguments are not allowed for method #{method_name}")
      end
      @signatures[method_name] ||= []
      @signatures[method_name] << Signature.new(
        args,
        delayed_args,
        options[:var_args],
        options[:var_kwargs],
        options[:deprecated] && options[:deprecated].map {|a| a.to_s})
    end

    # Determine the correct signature for the number of arguments
    # passed in for a given function.
    # If no signatures match, the first signature is returned for error messaging.
    #
    # @param method_name [Symbol] The name of the Ruby function to be called.
    # @param arg_arity [Integer] The number of unnamed arguments the function was passed.
    # @param kwarg_arity [Integer] The number of keyword arguments the function was passed.
    #
    # @return [{Symbol => Object}, nil]
    #   The signature options for the matching signature,
    #   or nil if no signatures are declared for this function. See {declare}.
    def self.signature(method_name, arg_arity, kwarg_arity)
      return unless @signatures[method_name]
      @signatures[method_name].each do |signature|
        sig_arity = signature.args.size
        return signature if sig_arity == arg_arity + kwarg_arity
        next unless sig_arity < arg_arity + kwarg_arity

        # We have enough args.
        # Now we need to figure out which args are varargs
        # and if the signature allows them.
        t_arg_arity, t_kwarg_arity = arg_arity, kwarg_arity
        if sig_arity > t_arg_arity
          # we transfer some kwargs arity to args arity
          # if it does not have enough args -- assuming the names will work out.
          t_kwarg_arity -= (sig_arity - t_arg_arity)
          t_arg_arity = sig_arity
        end

        if (t_arg_arity == sig_arity || t_arg_arity > sig_arity && signature.var_args) &&
           (t_kwarg_arity == 0 || t_kwarg_arity > 0 && signature.var_kwargs)
          return signature
        end
      end
      @signatures[method_name].first
    end

    # Sets the random seed used by Sass's internal random number generator.
    #
    # This can be used to ensure consistent random number sequences which
    # allows for consistent results when testing, etc.
    #
    # @param seed [Integer]
    # @return [Integer] The same seed.
    def self.random_seed=(seed)
      @random_number_generator = Random.new(seed)
    end

    # Get Sass's internal random number generator.
    #
    # @return [Random]
    def self.random_number_generator
      @random_number_generator ||= Random.new
    end

    # The context in which methods in {Script::Functions} are evaluated.
    # That means that all instance methods of {EvaluationContext}
    # are available to use in functions.
    class EvaluationContext
      include Functions
      include Value::Helpers

      # The human-readable names for [Sass::Script::Value::Base]. The default is
      # just the downcased name of the type.
      TYPE_NAMES = {:ArgList => 'variable argument list'}

      # The environment for this function. This environment's
      # {Environment#parent} is the global environment, and its
      # {Environment#caller} is a read-only view of the local environment of the
      # caller of this function.
      #
      # @return [Environment]
      attr_reader :environment

      # The options hash for the {Sass::Engine} that is processing the function call
      #
      # @return [{Symbol => Object}]
      attr_reader :options

      # @param environment [Environment] See \{#environment}
      def initialize(environment)
        @environment = environment
        @options = environment.options
      end

      # Asserts that the type of a given SassScript value
      # is the expected type (designated by a symbol).
      #
      # Valid types are `:Bool`, `:Color`, `:Number`, and `:String`.
      # Note that `:String` will match both double-quoted strings
      # and unquoted identifiers.
      #
      # @example
      #   assert_type value, :String
      #   assert_type value, :Number
      # @param value [Sass::Script::Value::Base] A SassScript value
      # @param type [Symbol, Array<Symbol>] The name(s) of the type the value is expected to be
      # @param name [String, Symbol, nil] The name of the argument.
      # @raise [ArgumentError] if value is not of the correct type.
      def assert_type(value, type, name = nil)
        valid_types = Array(type)
        found_type = valid_types.find do |t|
          value.is_a?(Sass::Script::Value.const_get(t)) ||
            t == :Map && value.is_a?(Sass::Script::Value::List) && value.value.empty?
        end

        if found_type
          value.check_deprecated_interp if found_type == :String
          return
        end

        err = if valid_types.size == 1
                "#{value.inspect} is not a #{TYPE_NAMES[type] || type.to_s.downcase}"
              else
                type_names = valid_types.map {|t| TYPE_NAMES[t] || t.to_s.downcase}
                "#{value.inspect} is not any of #{type_names.join(', ')}"
              end
        err = "$#{name.to_s.tr('_', '-')}: " + err if name
        raise ArgumentError.new(err)
      end

      # Asserts that the unit of the number is as expected.
      #
      # @example
      #   assert_unit number, "px"
      #   assert_unit number, nil
      # @param number [Sass::Script::Value::Number] The number to be validated.
      # @param unit [::String]
      #   The unit that the number must have.
      #   If nil, the number must be unitless.
      # @param name [::String] The name of the parameter being validated.
      # @raise [ArgumentError] if number is not of the correct unit or is not a number.
      def assert_unit(number, unit, name = nil)
        assert_type number, :Number, name
        return if number.is_unit?(unit)
        expectation = unit ? "have a unit of #{unit}" : "be unitless"
        if name
          raise ArgumentError.new("Expected $#{name} to #{expectation} but got #{number}")
        else
          raise ArgumentError.new("Expected #{number} to #{expectation}")
        end
      end

      # Asserts that the value is an integer.
      #
      # @example
      #   assert_integer 2px
      #   assert_integer 2.5px
      #     => SyntaxError: "Expected 2.5px to be an integer"
      #   assert_integer 2.5px, "width"
      #     => SyntaxError: "Expected width to be an integer but got 2.5px"
      # @param number [Sass::Script::Value::Base] The value to be validated.
      # @param name [::String] The name of the parameter being validated.
      # @raise [ArgumentError] if number is not an integer or is not a number.
      def assert_integer(number, name = nil)
        assert_type number, :Number, name
        return if number.int?
        if name
          raise ArgumentError.new("Expected $#{name} to be an integer but got #{number}")
        else
          raise ArgumentError.new("Expected #{number} to be an integer")
        end
      end

      # Performs a node that has been delayed for execution.
      #
      # @private
      # @param node [Sass::Script::Tree::Node,
      #   Sass::Script::Value::Base] When this is a tree node, it's
      #   performed in the caller's environment. When it's a value
      #   (which can happen when the value had to be performed already
      #   -- like for a splat), it's returned as-is.
      # @param env [Sass::Environment] The environment within which to perform the node.
      #   Defaults to the (read-only) environment of the caller.
      def perform(node, env = environment.caller)
        if node.is_a?(Sass::Script::Value::Base)
          node
        else
          node.perform(env)
        end
      end
    end

    class << self
      # Returns whether user function with a given name exists.
      #
      # @param function_name [String]
      # @return [Boolean]
      alias_method :callable?, :public_method_defined?

      private

      def include(*args)
        r = super
        # We have to re-include ourselves into EvaluationContext to work around
        # an icky Ruby restriction.
        EvaluationContext.send :include, self
        r
      end
    end

    # Creates a {Sass::Script::Value::Color Color} object from red, green, and
    # blue values.
    #
    # @see #rgba
    # @overload rgb($red, $green, $blue)
    #   @param $red [Sass::Script::Value::Number] The amount of red in the color.
    #     Must be between 0 and 255 inclusive, or between `0%` and `100%`
    #     inclusive
    #   @param $green [Sass::Script::Value::Number] The amount of green in the
    #     color. Must be between 0 and 255 inclusive, or between `0%` and `100%`
    #     inclusive
    #   @param $blue [Sass::Script::Value::Number] The amount of blue in the
    #     color. Must be between 0 and 255 inclusive, or between `0%` and `100%`
    #     inclusive
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if any parameter is the wrong type or out of bounds
    def rgb(red, green = nil, blue = nil)
      if green.nil?
        return unquoted_string("rgb(#{red})") if var?(red)
        raise ArgumentError.new("wrong number of arguments (1 for 3)")
      elsif blue.nil?
        return unquoted_string("rgb(#{red}, #{green})") if var?(red) || var?(green)
        raise ArgumentError.new("wrong number of arguments (2 for 3)")
      end

      if special_number?(red) || special_number?(green) || special_number?(blue)
        return unquoted_string("rgb(#{red}, #{green}, #{blue})")
      end
      assert_type red, :Number, :red
      assert_type green, :Number, :green
      assert_type blue, :Number, :blue

      color_attrs = [
        percentage_or_unitless(red, 255, "red"),
        percentage_or_unitless(green, 255, "green"),
        percentage_or_unitless(blue, 255, "blue")
      ]

      # Don't store the string representation for function-created colors, both
      # because it's not very useful and because some functions aren't supported
      # on older browsers.
      Sass::Script::Value::Color.new(color_attrs)
    end
    declare :rgb, [:red, :green, :blue]
    declare :rgb, [:red, :green]
    declare :rgb, [:red]

    # Creates a {Sass::Script::Value::Color Color} from red, green, blue, and
    # alpha values.
    # @see #rgb
    #
    # @overload rgba($red, $green, $blue, $alpha)
    #   @param $red [Sass::Script::Value::Number] The amount of red in the
    #     color. Must be between 0 and 255 inclusive or 0% and 100% inclusive
    #   @param $green [Sass::Script::Value::Number] The amount of green in the
    #     color. Must be between 0 and 255 inclusive or 0% and 100% inclusive
    #   @param $blue [Sass::Script::Value::Number] The amount of blue in the
    #     color. Must be between 0 and 255 inclusive or 0% and 100% inclusive
    #   @param $alpha [Sass::Script::Value::Number] The opacity of the color.
    #     Must be between 0 and 1 inclusive
    #   @return [Sass::Script::Value::Color]
    #   @raise [ArgumentError] if any parameter is the wrong type or out of
    #     bounds
    #
    # @overload rgba($color, $alpha)
    #   Sets the opacity of an existing color.
    #
    #   @example
    #     rgba(#102030, 0.5) => rgba(16, 32, 48, 0.5)
    #     rgba(blue, 0.2)    => rgba(0, 0, 255, 0.2)
    #
    #   @param $color [Sass::Script::Value::Color] The color whose opacity will
    #     be changed.
    #   @param $alpha [Sass::Script::Value::Number] The new opacity of the
    #     color. Must be between 0 and 1 inclusive
    #   @return [Sass::Script::Value::Color]
    #   @raise [ArgumentError] if `$alpha` is out of bounds or either parameter
    #     is the wrong type
    def rgba(*args)
      case args.size
      when 1
        return unquoted_string("rgba(#{args.first})") if var?(args.first)
        raise ArgumentError.new("wrong number of arguments (1 for 4)")
      when 2
        color, alpha = args

        if var?(color)
          return unquoted_string("rgba(#{color}, #{alpha})")
        elsif var?(alpha)
          if color.is_a?(Sass::Script::Value::Color)
            return unquoted_string("rgba(#{color.red}, #{color.green}, #{color.blue}, #{alpha})")
          else
            return unquoted_string("rgba(#{color}, #{alpha})")
          end
        end

        assert_type color, :Color, :color
        if special_number?(alpha)
          unquoted_string("rgba(#{color.red}, #{color.green}, #{color.blue}, #{alpha})")
        else
          assert_type alpha, :Number, :alpha
          color.with(:alpha => percentage_or_unitless(alpha, 1, "alpha"))
        end
      when 3
        if var?(args[0]) || var?(args[1]) || var?(args[2])
          unquoted_string("rgba(#{args.join(', ')})")
        else
          raise ArgumentError.new("wrong number of arguments (3 for 4)")
        end
      when 4
        red, green, blue, alpha = args
        if special_number?(red) || special_number?(green) ||
           special_number?(blue) || special_number?(alpha)
          unquoted_string("rgba(#{red}, #{green}, #{blue}, #{alpha})")
        else
          rgba(rgb(red, green, blue), alpha)
        end
      else
        raise ArgumentError.new("wrong number of arguments (#{args.size} for 4)")
      end
    end
    declare :rgba, [:red, :green, :blue, :alpha]
    declare :rgba, [:red, :green, :blue]
    declare :rgba, [:color, :alpha]
    declare :rgba, [:red]

    # Creates a {Sass::Script::Value::Color Color} from hue, saturation, and
    # lightness values. Uses the algorithm from the [CSS3 spec][].
    #
    # [CSS3 spec]: http://www.w3.org/TR/css3-color/#hsl-color
    #
    # @see #hsla
    # @overload hsl($hue, $saturation, $lightness)
    #   @param $hue [Sass::Script::Value::Number] The hue of the color. Should be
    #     between 0 and 360 degrees, inclusive
    #   @param $saturation [Sass::Script::Value::Number] The saturation of the
    #     color. Must be between `0%` and `100%`, inclusive
    #   @param $lightness [Sass::Script::Value::Number] The lightness of the
    #     color. Must be between `0%` and `100%`, inclusive
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$saturation` or `$lightness` are out of bounds
    #   or any parameter is the wrong type
    def hsl(hue, saturation = nil, lightness = nil)
      if saturation.nil?
        return unquoted_string("hsl(#{hue})") if var?(hue)
        raise ArgumentError.new("wrong number of arguments (1 for 3)")
      elsif lightness.nil?
        return unquoted_string("hsl(#{hue}, #{saturation})") if var?(hue) || var?(saturation)
        raise ArgumentError.new("wrong number of arguments (2 for 3)")
      end

      if special_number?(hue) || special_number?(saturation) || special_number?(lightness)
        unquoted_string("hsl(#{hue}, #{saturation}, #{lightness})")
      else
        hsla(hue, saturation, lightness, number(1))
      end
    end
    declare :hsl, [:hue, :saturation, :lightness]
    declare :hsl, [:hue, :saturation]
    declare :hsl, [:hue]

    # Creates a {Sass::Script::Value::Color Color} from hue,
    # saturation, lightness, and alpha values. Uses the algorithm from
    # the [CSS3 spec][].
    #
    # [CSS3 spec]: http://www.w3.org/TR/css3-color/#hsl-color
    #
    # @see #hsl
    # @overload hsla($hue, $saturation, $lightness, $alpha)
    #   @param $hue [Sass::Script::Value::Number] The hue of the color. Should be
    #     between 0 and 360 degrees, inclusive
    #   @param $saturation [Sass::Script::Value::Number] The saturation of the
    #     color. Must be between `0%` and `100%`, inclusive
    #   @param $lightness [Sass::Script::Value::Number] The lightness of the
    #     color. Must be between `0%` and `100%`, inclusive
    #   @param $alpha [Sass::Script::Value::Number] The opacity of the color. Must
    #     be between 0 and 1, inclusive
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$saturation`, `$lightness`, or `$alpha` are out
    #   of bounds or any parameter is the wrong type
    def hsla(hue, saturation = nil, lightness = nil, alpha = nil)
      if saturation.nil?
        return unquoted_string("hsla(#{hue})") if var?(hue)
        raise ArgumentError.new("wrong number of arguments (1 for 4)")
      elsif lightness.nil?
        return unquoted_string("hsla(#{hue}, #{saturation})") if var?(hue) || var?(saturation)
        raise ArgumentError.new("wrong number of arguments (2 for 4)")
      elsif alpha.nil?
        if var?(hue) || var?(saturation) || var?(lightness)
          return unquoted_string("hsla(#{hue}, #{saturation}, #{lightness})")
        else
          raise ArgumentError.new("wrong number of arguments (2 for 4)")
        end
      end

      if special_number?(hue) || special_number?(saturation) ||
         special_number?(lightness) || special_number?(alpha)
        return unquoted_string("hsla(#{hue}, #{saturation}, #{lightness}, #{alpha})")
      end
      assert_type hue, :Number, :hue
      assert_type saturation, :Number, :saturation
      assert_type lightness, :Number, :lightness
      assert_type alpha, :Number, :alpha

      h = hue.value
      s = saturation.value
      l = lightness.value

      # Don't store the string representation for function-created colors, both
      # because it's not very useful and because some functions aren't supported
      # on older browsers.
      Sass::Script::Value::Color.new(
        :hue => h, :saturation => s, :lightness => l,
        :alpha => percentage_or_unitless(alpha, 1, "alpha"))
    end
    declare :hsla, [:hue, :saturation, :lightness, :alpha]
    declare :hsla, [:hue, :saturation, :lightness]
    declare :hsla, [:hue, :saturation]
    declare :hsla, [:hue]

    # Gets the red component of a color. Calculated from HSL where necessary via
    # [this algorithm][hsl-to-rgb].
    #
    # [hsl-to-rgb]: http://www.w3.org/TR/css3-color/#hsl-color
    #
    # @overload red($color)
    #   @param $color [Sass::Script::Value::Color]
    # @return [Sass::Script::Value::Number] The red component, between 0 and 255
    #   inclusive
    # @raise [ArgumentError] if `$color` isn't a color
    def red(color)
      assert_type color, :Color, :color
      number(color.red)
    end
    declare :red, [:color]

    # Gets the green component of a color. Calculated from HSL where necessary
    # via [this algorithm][hsl-to-rgb].
    #
    # [hsl-to-rgb]: http://www.w3.org/TR/css3-color/#hsl-color
    #
    # @overload green($color)
    #   @param $color [Sass::Script::Value::Color]
    # @return [Sass::Script::Value::Number] The green component, between 0 and
    #   255 inclusive
    # @raise [ArgumentError] if `$color` isn't a color
    def green(color)
      assert_type color, :Color, :color
      number(color.green)
    end
    declare :green, [:color]

    # Gets the blue component of a color. Calculated from HSL where necessary
    # via [this algorithm][hsl-to-rgb].
    #
    # [hsl-to-rgb]: http://www.w3.org/TR/css3-color/#hsl-color
    #
    # @overload blue($color)
    #   @param $color [Sass::Script::Value::Color]
    # @return [Sass::Script::Value::Number] The blue component, between 0 and
    #   255 inclusive
    # @raise [ArgumentError] if `$color` isn't a color
    def blue(color)
      assert_type color, :Color, :color
      number(color.blue)
    end
    declare :blue, [:color]

    # Returns the hue component of a color. See [the CSS3 HSL
    # specification][hsl]. Calculated from RGB where necessary via [this
    # algorithm][rgb-to-hsl].
    #
    # [hsl]: http://en.wikipedia.org/wiki/HSL_and_HSV#Conversion_from_RGB_to_HSL_or_HSV
    # [rgb-to-hsl]: http://en.wikipedia.org/wiki/HSL_and_HSV#Conversion_from_RGB_to_HSL_or_HSV
    #
    # @overload hue($color)
    #   @param $color [Sass::Script::Value::Color]
    # @return [Sass::Script::Value::Number] The hue component, between 0deg and
    #   360deg
    # @raise [ArgumentError] if `$color` isn't a color
    def hue(color)
      assert_type color, :Color, :color
      number(color.hue, "deg")
    end
    declare :hue, [:color]

    # Returns the saturation component of a color. See [the CSS3 HSL
    # specification][hsl]. Calculated from RGB where necessary via [this
    # algorithm][rgb-to-hsl].
    #
    # [hsl]: http://en.wikipedia.org/wiki/HSL_and_HSV#Conversion_from_RGB_to_HSL_or_HSV
    # [rgb-to-hsl]: http://en.wikipedia.org/wiki/HSL_and_HSV#Conversion_from_RGB_to_HSL_or_HSV
    #
    # @overload saturation($color)
    #   @param $color [Sass::Script::Value::Color]
    # @return [Sass::Script::Value::Number] The saturation component, between 0%
    #   and 100%
    # @raise [ArgumentError] if `$color` isn't a color
    def saturation(color)
      assert_type color, :Color, :color
      number(color.saturation, "%")
    end
    declare :saturation, [:color]

    # Returns the lightness component of a color. See [the CSS3 HSL
    # specification][hsl]. Calculated from RGB where necessary via [this
    # algorithm][rgb-to-hsl].
    #
    # [hsl]: http://en.wikipedia.org/wiki/HSL_and_HSV#Conversion_from_RGB_to_HSL_or_HSV
    # [rgb-to-hsl]: http://en.wikipedia.org/wiki/HSL_and_HSV#Conversion_from_RGB_to_HSL_or_HSV
    #
    # @overload lightness($color)
    #   @param $color [Sass::Script::Value::Color]
    # @return [Sass::Script::Value::Number] The lightness component, between 0%
    #   and 100%
    # @raise [ArgumentError] if `$color` isn't a color
    def lightness(color)
      assert_type color, :Color, :color
      number(color.lightness, "%")
    end
    declare :lightness, [:color]

    # Returns the alpha component (opacity) of a color. This is 1 unless
    # otherwise specified.
    #
    # This function also supports the proprietary Microsoft `alpha(opacity=20)`
    # syntax as a special case.
    #
    # @overload alpha($color)
    #   @param $color [Sass::Script::Value::Color]
    # @return [Sass::Script::Value::Number] The alpha component, between 0 and 1
    # @raise [ArgumentError] if `$color` isn't a color
    def alpha(*args)
      if args.all? do |a|
           a.is_a?(Sass::Script::Value::String) && a.type == :identifier &&
             a.value =~ /^[a-zA-Z]+\s*=/
         end
        # Support the proprietary MS alpha() function
        return identifier("alpha(#{args.map {|a| a.to_s}.join(', ')})")
      end

      raise ArgumentError.new("wrong number of arguments (#{args.size} for 1)") if args.size != 1

      assert_type args.first, :Color, :color
      number(args.first.alpha)
    end
    declare :alpha, [:color]

    # Returns the alpha component (opacity) of a color. This is 1 unless
    # otherwise specified.
    #
    # @overload opacity($color)
    #   @param $color [Sass::Script::Value::Color]
    # @return [Sass::Script::Value::Number] The alpha component, between 0 and 1
    # @raise [ArgumentError] if `$color` isn't a color
    def opacity(color)
      if color.is_a?(Sass::Script::Value::Number)
        return identifier("opacity(#{color})")
      end
      assert_type color, :Color, :color
      number(color.alpha)
    end
    declare :opacity, [:color]

    # Makes a color more opaque. Takes a color and a number between 0 and 1, and
    # returns a color with the opacity increased by that amount.
    #
    # @see #transparentize
    # @example
    #   opacify(rgba(0, 0, 0, 0.5), 0.1) => rgba(0, 0, 0, 0.6)
    #   opacify(rgba(0, 0, 17, 0.8), 0.2) => #001
    # @overload opacify($color, $amount)
    #   @param $color [Sass::Script::Value::Color]
    #   @param $amount [Sass::Script::Value::Number] The amount to increase the
    #     opacity by, between 0 and 1
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$amount` is out of bounds, or either parameter
    #   is the wrong type
    def opacify(color, amount)
      _adjust(color, amount, :alpha, 0..1, :+)
    end
    declare :opacify, [:color, :amount]

    alias_method :fade_in, :opacify
    declare :fade_in, [:color, :amount]

    # Makes a color more transparent. Takes a color and a number between 0 and
    # 1, and returns a color with the opacity decreased by that amount.
    #
    # @see #opacify
    # @example
    #   transparentize(rgba(0, 0, 0, 0.5), 0.1) => rgba(0, 0, 0, 0.4)
    #   transparentize(rgba(0, 0, 0, 0.8), 0.2) => rgba(0, 0, 0, 0.6)
    # @overload transparentize($color, $amount)
    #   @param $color [Sass::Script::Value::Color]
    #   @param $amount [Sass::Script::Value::Number] The amount to decrease the
    #     opacity by, between 0 and 1
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$amount` is out of bounds, or either parameter
    #   is the wrong type
    def transparentize(color, amount)
      _adjust(color, amount, :alpha, 0..1, :-)
    end
    declare :transparentize, [:color, :amount]

    alias_method :fade_out, :transparentize
    declare :fade_out, [:color, :amount]

    # Makes a color lighter. Takes a color and a number between `0%` and `100%`,
    # and returns a color with the lightness increased by that amount.
    #
    # @see #darken
    # @example
    #   lighten(hsl(0, 0%, 0%), 30%) => hsl(0, 0, 30)
    #   lighten(#800, 20%) => #e00
    # @overload lighten($color, $amount)
    #   @param $color [Sass::Script::Value::Color]
    #   @param $amount [Sass::Script::Value::Number] The amount to increase the
    #     lightness by, between `0%` and `100%`
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$amount` is out of bounds, or either parameter
    #   is the wrong type
    def lighten(color, amount)
      _adjust(color, amount, :lightness, 0..100, :+, "%")
    end
    declare :lighten, [:color, :amount]

    # Makes a color darker. Takes a color and a number between 0% and 100%, and
    # returns a color with the lightness decreased by that amount.
    #
    # @see #lighten
    # @example
    #   darken(hsl(25, 100%, 80%), 30%) => hsl(25, 100%, 50%)
    #   darken(#800, 20%) => #200
    # @overload darken($color, $amount)
    #   @param $color [Sass::Script::Value::Color]
    #   @param $amount [Sass::Script::Value::Number] The amount to decrease the
    #     lightness by, between `0%` and `100%`
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$amount` is out of bounds, or either parameter
    #   is the wrong type
    def darken(color, amount)
      _adjust(color, amount, :lightness, 0..100, :-, "%")
    end
    declare :darken, [:color, :amount]

    # Makes a color more saturated. Takes a color and a number between 0% and
    # 100%, and returns a color with the saturation increased by that amount.
    #
    # @see #desaturate
    # @example
    #   saturate(hsl(120, 30%, 90%), 20%) => hsl(120, 50%, 90%)
    #   saturate(#855, 20%) => #9e3f3f
    # @overload saturate($color, $amount)
    #   @param $color [Sass::Script::Value::Color]
    #   @param $amount [Sass::Script::Value::Number] The amount to increase the
    #     saturation by, between `0%` and `100%`
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$amount` is out of bounds, or either parameter
    #   is the wrong type
    def saturate(color, amount = nil)
      # Support the filter effects definition of saturate.
      # https://dvcs.w3.org/hg/FXTF/raw-file/tip/filters/index.html
      return identifier("saturate(#{color})") if amount.nil?
      _adjust(color, amount, :saturation, 0..100, :+, "%")
    end
    declare :saturate, [:color, :amount]
    declare :saturate, [:amount]

    # Makes a color less saturated. Takes a color and a number between 0% and
    # 100%, and returns a color with the saturation decreased by that value.
    #
    # @see #saturate
    # @example
    #   desaturate(hsl(120, 30%, 90%), 20%) => hsl(120, 10%, 90%)
    #   desaturate(#855, 20%) => #726b6b
    # @overload desaturate($color, $amount)
    #   @param $color [Sass::Script::Value::Color]
    #   @param $amount [Sass::Script::Value::Number] The amount to decrease the
    #     saturation by, between `0%` and `100%`
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$amount` is out of bounds, or either parameter
    #   is the wrong type
    def desaturate(color, amount)
      _adjust(color, amount, :saturation, 0..100, :-, "%")
    end
    declare :desaturate, [:color, :amount]

    # Changes the hue of a color. Takes a color and a number of degrees (usually
    # between `-360deg` and `360deg`), and returns a color with the hue rotated
    # along the color wheel by that amount.
    #
    # @example
    #   adjust-hue(hsl(120, 30%, 90%), 60deg) => hsl(180, 30%, 90%)
    #   adjust-hue(hsl(120, 30%, 90%), -60deg) => hsl(60, 30%, 90%)
    #   adjust-hue(#811, 45deg) => #886a11
    # @overload adjust_hue($color, $degrees)
    #   @param $color [Sass::Script::Value::Color]
    #   @param $degrees [Sass::Script::Value::Number] The number of degrees to
    #     rotate the hue
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if either parameter is the wrong type
    def adjust_hue(color, degrees)
      assert_type color, :Color, :color
      assert_type degrees, :Number, :degrees
      color.with(:hue => color.hue + degrees.value)
    end
    declare :adjust_hue, [:color, :degrees]

    # Converts a color into the format understood by IE filters.
    #
    # @example
    #   ie-hex-str(#abc) => #FFAABBCC
    #   ie-hex-str(#3322BB) => #FF3322BB
    #   ie-hex-str(rgba(0, 255, 0, 0.5)) => #8000FF00
    # @overload ie_hex_str($color)
    #   @param $color [Sass::Script::Value::Color]
    # @return [Sass::Script::Value::String] The IE-formatted string
    #   representation of the color
    # @raise [ArgumentError] if `$color` isn't a color
    def ie_hex_str(color)
      assert_type color, :Color, :color
      alpha = Sass::Util.round(color.alpha * 255).to_s(16).rjust(2, '0')
      identifier("##{alpha}#{color.send(:hex_str)[1..-1]}".upcase)
    end
    declare :ie_hex_str, [:color]

    # Increases or decreases one or more properties of a color. This can change
    # the red, green, blue, hue, saturation, value, and alpha properties. The
    # properties are specified as keyword arguments, and are added to or
    # subtracted from the color's current value for that property.
    #
    # All properties are optional. You can't specify both RGB properties
    # (`$red`, `$green`, `$blue`) and HSL properties (`$hue`, `$saturation`,
    # `$value`) at the same time.
    #
    # @example
    #   adjust-color(#102030, $blue: 5) => #102035
    #   adjust-color(#102030, $red: -5, $blue: 5) => #0b2035
    #   adjust-color(hsl(25, 100%, 80%), $lightness: -30%, $alpha: -0.4) => hsla(25, 100%, 50%, 0.6)
    # @overload adjust_color($color, [$red], [$green], [$blue], [$hue], [$saturation], [$lightness], [$alpha])
    #   @param $color [Sass::Script::Value::Color]
    #   @param $red [Sass::Script::Value::Number] The adjustment to make on the
    #     red component, between -255 and 255 inclusive
    #   @param $green [Sass::Script::Value::Number] The adjustment to make on the
    #     green component, between -255 and 255 inclusive
    #   @param $blue [Sass::Script::Value::Number] The adjustment to make on the
    #     blue component, between -255 and 255 inclusive
    #   @param $hue [Sass::Script::Value::Number] The adjustment to make on the
    #     hue component, in degrees
    #   @param $saturation [Sass::Script::Value::Number] The adjustment to make on
    #     the saturation component, between `-100%` and `100%` inclusive
    #   @param $lightness [Sass::Script::Value::Number] The adjustment to make on
    #     the lightness component, between `-100%` and `100%` inclusive
    #   @param $alpha [Sass::Script::Value::Number] The adjustment to make on the
    #     alpha component, between -1 and 1 inclusive
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if any parameter is the wrong type or out-of
    #   bounds, or if RGB properties and HSL properties are adjusted at the
    #   same time
    def adjust_color(color, kwargs)
      assert_type color, :Color, :color
      with = Sass::Util.map_hash(
        "red" => [-255..255, ""],
        "green" => [-255..255, ""],
        "blue" => [-255..255, ""],
        "hue" => nil,
        "saturation" => [-100..100, "%"],
        "lightness" => [-100..100, "%"],
        "alpha" => [-1..1, ""]
      ) do |name, (range, units)|
        val = kwargs.delete(name)
        next unless val
        assert_type val, :Number, name
        Sass::Util.check_range("$#{name}: Amount", range, val, units) if range
        adjusted = color.send(name) + val.value
        adjusted = [0, Sass::Util.restrict(adjusted, range)].max if range
        [name.to_sym, adjusted]
      end

      unless kwargs.empty?
        name, val = kwargs.to_a.first
        raise ArgumentError.new("Unknown argument $#{name} (#{val})")
      end

      color.with(with)
    end
    declare :adjust_color, [:color], :var_kwargs => true

    # Fluidly scales one or more properties of a color. Unlike
    # \{#adjust_color adjust-color}, which changes a color's properties by fixed
    # amounts, \{#scale_color scale-color} fluidly changes them based on how
    # high or low they already are. That means that lightening an already-light
    # color with \{#scale_color scale-color} won't change the lightness much,
    # but lightening a dark color by the same amount will change it more
    # dramatically. This has the benefit of making `scale-color($color, ...)`
    # have a similar effect regardless of what `$color` is.
    #
    # For example, the lightness of a color can be anywhere between `0%` and
    # `100%`. If `scale-color($color, $lightness: 40%)` is called, the resulting
    # color's lightness will be 40% of the way between its original lightness
    # and 100. If `scale-color($color, $lightness: -40%)` is called instead, the
    # lightness will be 40% of the way between the original and 0.
    #
    # This can change the red, green, blue, saturation, value, and alpha
    # properties. The properties are specified as keyword arguments. All
    # arguments should be percentages between `0%` and `100%`.
    #
    # All properties are optional. You can't specify both RGB properties
    # (`$red`, `$green`, `$blue`) and HSL properties (`$saturation`, `$value`)
    # at the same time.
    #
    # @example
    #   scale-color(hsl(120, 70%, 80%), $lightness: 50%) => hsl(120, 70%, 90%)
    #   scale-color(rgb(200, 150%, 170%), $green: -40%, $blue: 70%) => rgb(200, 90, 229)
    #   scale-color(hsl(200, 70%, 80%), $saturation: -90%, $alpha: -30%) => hsla(200, 7%, 80%, 0.7)
    # @overload scale_color($color, [$red], [$green], [$blue], [$saturation], [$lightness], [$alpha])
    #   @param $color [Sass::Script::Value::Color]
    #   @param $red [Sass::Script::Value::Number]
    #   @param $green [Sass::Script::Value::Number]
    #   @param $blue [Sass::Script::Value::Number]
    #   @param $saturation [Sass::Script::Value::Number]
    #   @param $lightness [Sass::Script::Value::Number]
    #   @param $alpha [Sass::Script::Value::Number]
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if any parameter is the wrong type or out-of
    #   bounds, or if RGB properties and HSL properties are adjusted at the
    #   same time
    def scale_color(color, kwargs)
      assert_type color, :Color, :color
      with = Sass::Util.map_hash(
        "red" => 255,
        "green" => 255,
        "blue" => 255,
        "saturation" => 100,
        "lightness" => 100,
        "alpha" => 1
      ) do |name, max|
        val = kwargs.delete(name)
        next unless val
        assert_type val, :Number, name
        assert_unit val, '%', name
        Sass::Util.check_range("$#{name}: Amount", -100..100, val, '%')

        current = color.send(name)
        scale = val.value / 100.0
        diff = scale > 0 ? max - current : current
        [name.to_sym, current + diff * scale]
      end

      unless kwargs.empty?
        name, val = kwargs.to_a.first
        raise ArgumentError.new("Unknown argument $#{name} (#{val})")
      end

      color.with(with)
    end
    declare :scale_color, [:color], :var_kwargs => true

    # Changes one or more properties of a color. This can change the red, green,
    # blue, hue, saturation, value, and alpha properties. The properties are
    # specified as keyword arguments, and replace the color's current value for
    # that property.
    #
    # All properties are optional. You can't specify both RGB properties
    # (`$red`, `$green`, `$blue`) and HSL properties (`$hue`, `$saturation`,
    # `$value`) at the same time.
    #
    # @example
    #   change-color(#102030, $blue: 5) => #102005
    #   change-color(#102030, $red: 120, $blue: 5) => #782005
    #   change-color(hsl(25, 100%, 80%), $lightness: 40%, $alpha: 0.8) => hsla(25, 100%, 40%, 0.8)
    # @overload change_color($color, [$red], [$green], [$blue], [$hue], [$saturation], [$lightness], [$alpha])
    #   @param $color [Sass::Script::Value::Color]
    #   @param $red [Sass::Script::Value::Number] The new red component for the
    #     color, within 0 and 255 inclusive
    #   @param $green [Sass::Script::Value::Number] The new green component for
    #     the color, within 0 and 255 inclusive
    #   @param $blue [Sass::Script::Value::Number] The new blue component for the
    #     color, within 0 and 255 inclusive
    #   @param $hue [Sass::Script::Value::Number] The new hue component for the
    #     color, in degrees
    #   @param $saturation [Sass::Script::Value::Number] The new saturation
    #     component for the color, between `0%` and `100%` inclusive
    #   @param $lightness [Sass::Script::Value::Number] The new lightness
    #     component for the color, within `0%` and `100%` inclusive
    #   @param $alpha [Sass::Script::Value::Number] The new alpha component for
    #     the color, within 0 and 1 inclusive
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if any parameter is the wrong type or out-of
    #   bounds, or if RGB properties and HSL properties are adjusted at the
    #   same time
    def change_color(color, kwargs)
      assert_type color, :Color, :color
      with = Sass::Util.map_hash(
        'red' => ['Red value', 0..255],
        'green' => ['Green value', 0..255],
        'blue' => ['Blue value', 0..255],
        'hue' => [],
        'saturation' => ['Saturation', 0..100, '%'],
        'lightness' => ['Lightness', 0..100, '%'],
        'alpha' => ['Alpha channel', 0..1]
      ) do |name, (desc, range, unit)|
        val = kwargs.delete(name)
        next unless val
        assert_type val, :Number, name

        if range
          val = Sass::Util.check_range(desc, range, val, unit)
        else
          val = val.value
        end

        [name.to_sym, val]
      end

      unless kwargs.empty?
        name, val = kwargs.to_a.first
        raise ArgumentError.new("Unknown argument $#{name} (#{val})")
      end

      color.with(with)
    end
    declare :change_color, [:color], :var_kwargs => true

    # Mixes two colors together. Specifically, takes the average of each of the
    # RGB components, optionally weighted by the given percentage. The opacity
    # of the colors is also considered when weighting the components.
    #
    # The weight specifies the amount of the first color that should be included
    # in the returned color. The default, `50%`, means that half the first color
    # and half the second color should be used. `25%` means that a quarter of
    # the first color and three quarters of the second color should be used.
    #
    # @example
    #   mix(#f00, #00f) => #7f007f
    #   mix(#f00, #00f, 25%) => #3f00bf
    #   mix(rgba(255, 0, 0, 0.5), #00f) => rgba(63, 0, 191, 0.75)
    # @overload mix($color1, $color2, $weight: 50%)
    #   @param $color1 [Sass::Script::Value::Color]
    #   @param $color2 [Sass::Script::Value::Color]
    #   @param $weight [Sass::Script::Value::Number] The relative weight of each
    #     color. Closer to `100%` gives more weight to `$color1`, closer to `0%`
    #     gives more weight to `$color2`
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$weight` is out of bounds or any parameter is
    #   the wrong type
    def mix(color1, color2, weight = number(50))
      assert_type color1, :Color, :color1
      assert_type color2, :Color, :color2
      assert_type weight, :Number, :weight

      Sass::Util.check_range("Weight", 0..100, weight, '%')

      # This algorithm factors in both the user-provided weight (w) and the
      # difference between the alpha values of the two colors (a) to decide how
      # to perform the weighted average of the two RGB values.
      #
      # It works by first normalizing both parameters to be within [-1, 1],
      # where 1 indicates "only use color1", -1 indicates "only use color2", and
      # all values in between indicated a proportionately weighted average.
      #
      # Once we have the normalized variables w and a, we apply the formula
      # (w + a)/(1 + w*a) to get the combined weight (in [-1, 1]) of color1.
      # This formula has two especially nice properties:
      #
      #   * When either w or a are -1 or 1, the combined weight is also that number
      #     (cases where w * a == -1 are undefined, and handled as a special case).
      #
      #   * When a is 0, the combined weight is w, and vice versa.
      #
      # Finally, the weight of color1 is renormalized to be within [0, 1]
      # and the weight of color2 is given by 1 minus the weight of color1.
      p = (weight.value / 100.0).to_f
      w = p * 2 - 1
      a = color1.alpha - color2.alpha

      w1 = ((w * a == -1 ? w : (w + a) / (1 + w * a)) + 1) / 2.0
      w2 = 1 - w1

      rgba = color1.rgb.zip(color2.rgb).map {|v1, v2| v1 * w1 + v2 * w2}
      rgba << color1.alpha * p + color2.alpha * (1 - p)
      rgb_color(*rgba)
    end
    declare :mix, [:color1, :color2]
    declare :mix, [:color1, :color2, :weight]

    # Converts a color to grayscale. This is identical to `desaturate(color,
    # 100%)`.
    #
    # @see #desaturate
    # @overload grayscale($color)
    #   @param $color [Sass::Script::Value::Color]
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$color` isn't a color
    def grayscale(color)
      if color.is_a?(Sass::Script::Value::Number)
        return identifier("grayscale(#{color})")
      end
      desaturate color, number(100)
    end
    declare :grayscale, [:color]

    # Returns the complement of a color. This is identical to `adjust-hue(color,
    # 180deg)`.
    #
    # @see #adjust_hue #adjust-hue
    # @overload complement($color)
    #   @param $color [Sass::Script::Value::Color]
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$color` isn't a color
    def complement(color)
      adjust_hue color, number(180)
    end
    declare :complement, [:color]

    # Returns the inverse (negative) of a color. The red, green, and blue values
    # are inverted, while the opacity is left alone.
    #
    # @overload invert($color)
    #   @param $color [Sass::Script::Value::Color]
    # @overload invert($color, $weight: 100%)
    #   @param $color [Sass::Script::Value::Color]
    #   @param $weight [Sass::Script::Value::Number] The relative weight of the
    #     color color's inverse
    # @return [Sass::Script::Value::Color]
    # @raise [ArgumentError] if `$color` isn't a color or `$weight`
    #   isn't a percentage between 0% and 100%
    def invert(color, weight = number(100))
      if color.is_a?(Sass::Script::Value::Number)
        return identifier("invert(#{color})")
      end

      assert_type color, :Color, :color
      inv = color.with(
        :red => (255 - color.red),
        :green => (255 - color.green),
        :blue => (255 - color.blue))

      mix(inv, color, weight)
    end
    declare :invert, [:color]
    declare :invert, [:color, :weight]

    # Removes quotes from a string. If the string is already unquoted, this will
    # return it unmodified.
    #
    # @see #quote
    # @example
    #   unquote("foo") => foo
    #   unquote(foo) => foo
    # @overload unquote($string)
    #   @param $string [Sass::Script::Value::String]
    # @return [Sass::Script::Value::String]
    # @raise [ArgumentError] if `$string` isn't a string
    def unquote(string)
      unless string.is_a?(Sass::Script::Value::String)
        # Don't warn multiple times for the same source line.
        $_sass_warned_for_unquote ||= Set.new
        frame = environment.stack.frames.last
        key = [frame.filename, frame.line] if frame
        return string if frame && $_sass_warned_for_unquote.include?(key)
        $_sass_warned_for_unquote << key if frame

        Sass::Util.sass_warn(<<MESSAGE.strip)
DEPRECATION WARNING: Passing #{string.to_sass}, a non-string value, to unquote()
will be an error in future versions of Sass.
#{environment.stack.to_s.gsub(/^/, ' ' * 8)}
MESSAGE
        return string
      end

      string.check_deprecated_interp
      return string if string.type == :identifier
      identifier(string.value)
    end
    declare :unquote, [:string]

    # Add quotes to a string if the string isn't quoted,
    # or returns the same string if it is.
    #
    # @see #unquote
    # @example
    #   quote("foo") => "foo"
    #   quote(foo) => "foo"
    # @overload quote($string)
    #   @param $string [Sass::Script::Value::String]
    # @return [Sass::Script::Value::String]
    # @raise [ArgumentError] if `$string` isn't a string
    def quote(string)
      assert_type string, :String, :string
      if string.type != :string
        quoted_string(string.value)
      else
        string
      end
    end
    declare :quote, [:string]

    # Returns the number of characters in a string.
    #
    # @example
    #   str-length("foo") => 3
    # @overload str_length($string)
    #   @param $string [Sass::Script::Value::String]
    # @return [Sass::Script::Value::Number]
    # @raise [ArgumentError] if `$string` isn't a string
    def str_length(string)
      assert_type string, :String, :string
      number(string.value.size)
    end
    declare :str_length, [:string]

    # Inserts `$insert` into `$string` at `$index`.
    #
    # Note that unlike some languages, the first character in a Sass string is
    # number 1, the second number 2, and so forth.
    #
    # @example
    #   str-insert("abcd", "X", 1) => "Xabcd"
    #   str-insert("abcd", "X", 4) => "abcXd"
    #   str-insert("abcd", "X", 5) => "abcdX"
    #
    # @overload str_insert($string, $insert, $index)
    #   @param $string [Sass::Script::Value::String]
    #   @param $insert [Sass::Script::Value::String]
    #   @param $index [Sass::Script::Value::Number] The position at which
    #     `$insert` will be inserted. Negative indices count from the end of
    #     `$string`. An index that's outside the bounds of the string will insert
    #     `$insert` at the front or back of the string
    # @return [Sass::Script::Value::String] The result string. This will be
    #   quoted if and only if `$string` was quoted
    # @raise [ArgumentError] if any parameter is the wrong type
    def str_insert(original, insert, index)
      assert_type original, :String, :string
      assert_type insert, :String, :insert
      assert_integer index, :index
      assert_unit index, nil, :index
      insertion_point = if index.to_i > 0
                          [index.to_i - 1, original.value.size].min
                        else
                          [index.to_i, -original.value.size - 1].max
                        end
      result = original.value.dup.insert(insertion_point, insert.value)
      Sass::Script::Value::String.new(result, original.type)
    end
    declare :str_insert, [:string, :insert, :index]

    # Returns the index of the first occurrence of `$substring` in `$string`. If
    # there is no such occurrence, returns `null`.
    #
    # Note that unlike some languages, the first character in a Sass string is
    # number 1, the second number 2, and so forth.
    #
    # @example
    #   str-index(abcd, a)  => 1
    #   str-index(abcd, ab) => 1
    #   str-index(abcd, X)  => null
    #   str-index(abcd, c)  => 3
    #
    # @overload str_index($string, $substring)
    #   @param $string [Sass::Script::Value::String]
    #   @param $substring [Sass::Script::Value::String]
    # @return [Sass::Script::Value::Number, Sass::Script::Value::Null]
    # @raise [ArgumentError] if any parameter is the wrong type
    def str_index(string, substring)
      assert_type string, :String, :string
      assert_type substring, :String, :substring
      index = string.value.index(substring.value)
      index ? number(index + 1) : null
    end
    declare :str_index, [:string, :substring]

    # Extracts a substring from `$string`. The substring will begin at index
    # `$start-at` and ends at index `$end-at`.
    #
    # Note that unlike some languages, the first character in a Sass string is
    # number 1, the second number 2, and so forth.
    #
    # @example
    #  str-slice("abcd", 2, 3)   => "bc"
    #  str-slice("abcd", 2)      => "bcd"
    #  str-slice("abcd", -3, -2) => "bc"
    #  str-slice("abcd", 2, -2)  => "bc"
    #
    # @overload str_slice($string, $start-at, $end-at: -1)
    #   @param $start-at [Sass::Script::Value::Number] The index of the first
    #     character of the substring. If this is negative, it counts from the end
    #     of `$string`
    #   @param $end-at [Sass::Script::Value::Number] The index of the last
    #     character of the substring. If this is negative, it counts from the end
    #     of `$string`. Defaults to -1
    #   @return [Sass::Script::Value::String] The substring. This will be quoted
    #     if and only if `$string` was quoted
    # @raise [ArgumentError] if any parameter is the wrong type
    def str_slice(string, start_at, end_at = nil)
      assert_type string, :String, :string
      assert_unit start_at, nil, "start-at"

      end_at = number(-1) if end_at.nil?
      assert_unit end_at, nil, "end-at"

      return Sass::Script::Value::String.new("", string.type) if end_at.value == 0
      s = start_at.value > 0 ? start_at.value - 1 : start_at.value
      e = end_at.value > 0 ? end_at.value - 1 : end_at.value
      s = string.value.length + s if s < 0
      s = 0 if s < 0
      e = string.value.length + e if e < 0
      return Sass::Script::Value::String.new("", string.type) if e < 0
      extracted = string.value.slice(s..e)
      Sass::Script::Value::String.new(extracted || "", string.type)
    end
    declare :str_slice, [:string, :start_at]
    declare :str_slice, [:string, :start_at, :end_at]

    # Converts a string to upper case.
    #
    # @example
    #   to-upper-case(abcd) => ABCD
    #
    # @overload to_upper_case($string)
    #   @param $string [Sass::Script::Value::String]
    # @return [Sass::Script::Value::String]
    # @raise [ArgumentError] if `$string` isn't a string
    def to_upper_case(string)
      assert_type string, :String, :string
      Sass::Script::Value::String.new(Sass::Util.upcase(string.value), string.type)
    end
    declare :to_upper_case, [:string]

    # Convert a string to lower case,
    #
    # @example
    #   to-lower-case(ABCD) => abcd
    #
    # @overload to_lower_case($string)
    #   @param $string [Sass::Script::Value::String]
    # @return [Sass::Script::Value::String]
    # @raise [ArgumentError] if `$string` isn't a string
    def to_lower_case(string)
      assert_type string, :String, :string
      Sass::Script::Value::String.new(Sass::Util.downcase(string.value), string.type)
    end
    declare :to_lower_case, [:string]

    # Returns the type of a value.
    #
    # @example
    #   type-of(100px)  => number
    #   type-of(asdf)   => string
    #   type-of("asdf") => string
    #   type-of(true)   => bool
    #   type-of(#fff)   => color
    #   type-of(blue)   => color
    #   type-of(null)   => null
    #   type-of(a b c)  => list
    #   type-of((a: 1, b: 2)) => map
    #   type-of(get-function("foo")) => function
    #
    # @overload type_of($value)
    #   @param $value [Sass::Script::Value::Base] The value to inspect
    # @return [Sass::Script::Value::String] The unquoted string name of the
    #   value's type
    def type_of(value)
      value.check_deprecated_interp if value.is_a?(Sass::Script::Value::String)
      identifier(value.class.name.gsub(/Sass::Script::Value::/, '').downcase)
    end
    declare :type_of, [:value]

    # Returns whether a feature exists in the current Sass runtime.
    #
    # The following features are supported:
    #
    # * `global-variable-shadowing` indicates that a local variable will shadow
    #   a global variable unless `!global` is used.
    #
    # * `extend-selector-pseudoclass` indicates that `@extend` will reach into
    #   selector pseudoclasses like `:not`.
    #
    # * `units-level-3` indicates full support for unit arithmetic using units
    #   defined in the [Values and Units Level 3][] spec.
    #
    # [Values and Units Level 3]: http://www.w3.org/TR/css3-values/
    #
    # * `at-error` indicates that the Sass `@error` directive is supported.
    #
    # * `custom-property` indicates that the [Custom Properties Level 1][] spec
    #   is supported. This means that custom properties are parsed statically,
    #   with only interpolation treated as SassScript.
    #
    # [Custom Properties Level 1]: https://www.w3.org/TR/css-variables-1/
    #
    # @example
    #   feature-exists(some-feature-that-exists) => true
    #   feature-exists(what-is-this-i-dont-know) => false
    #
    # @overload feature_exists($feature)
    #   @param $feature [Sass::Script::Value::String] The name of the feature
    # @return [Sass::Script::Value::Bool] Whether the feature is supported in this version of Sass
    # @raise [ArgumentError] if `$feature` isn't a string
    def feature_exists(feature)
      assert_type feature, :String, :feature
      bool(Sass.has_feature?(feature.value))
    end
    declare :feature_exists, [:feature]

    # Returns a reference to a function for later invocation with the `call()` function.
    #
    # If `$css` is `false`, the function reference may refer to a function
    # defined in your stylesheet or built-in to the host environment. If it's
    # `true` it will refer to a plain-CSS function.
    #
    # @example
    #   get-function("rgb")
    #
    #   @function myfunc { @return "something"; }
    #   get-function("myfunc")
    #
    # @overload get_function($name, $css: false)
    #   @param name [Sass::Script::Value::String] The name of the function being referenced.
    #   @param css [Sass::Script::Value::Bool] Whether to get a plain CSS function.
    #
    # @return [Sass::Script::Value::Function] A function reference.
    def get_function(name, kwargs = {})
      assert_type name, :String, :name

      css = if kwargs.has_key?("css")
              v = kwargs.delete("css")
              assert_type v, :Bool, :css
              v.value
            else
              false
            end

      if kwargs.any?
        raise ArgumentError.new("Illegal keyword argument '#{kwargs.keys.first}'")
      end

      if css
        return Sass::Script::Value::Function.new(
          Sass::Callable.new(name.value, nil, nil, nil, nil, nil, "function", :css))
      end

      callable = environment.caller.function(name.value) ||
        (Sass::Script::Functions.callable?(name.value.tr("-", "_")) &&
         Sass::Callable.new(name.value, nil, nil, nil, nil, nil, "function", :builtin))

      if callable
        Sass::Script::Value::Function.new(callable)
      else
        raise Sass::SyntaxError.new("Function not found: #{name}")
      end
    end
    declare :get_function, [:name], :var_kwargs => true

    # Returns the unit(s) associated with a number. Complex units are sorted in
    # alphabetical order by numerator and denominator.
    #
    # @example
    #   unit(100) => ""
    #   unit(100px) => "px"
    #   unit(3em) => "em"
    #   unit(10px * 5em) => "em*px"
    #   unit(10px * 5em / 30cm / 1rem) => "em*px/cm*rem"
    # @overload unit($number)
    #   @param $number [Sass::Script::Value::Number]
    # @return [Sass::Script::Value::String] The unit(s) of the number, as a
    #   quoted string
    # @raise [ArgumentError] if `$number` isn't a number
    def unit(number)
      assert_type number, :Number, :number
      quoted_string(number.unit_str)
    end
    declare :unit, [:number]

    # Returns whether a number has units.
    #
    # @example
    #   unitless(100) => true
    #   unitless(100px) => false
    # @overload unitless($number)
    #   @param $number [Sass::Script::Value::Number]
    # @return [Sass::Script::Value::Bool]
    # @raise [ArgumentError] if `$number` isn't a number
    def unitless(number)
      assert_type number, :Number, :number
      bool(number.unitless?)
    end
    declare :unitless, [:number]

    # Returns whether two numbers can added, subtracted, or compared.
    #
    # @example
    #   comparable(2px, 1px) => true
    #   comparable(100px, 3em) => false
    #   comparable(10cm, 3mm) => true
    # @overload comparable($number1, $number2)
    #   @param $number1 [Sass::Script::Value::Number]
    #   @param $number2 [Sass::Script::Value::Number]
    # @return [Sass::Script::Value::Bool]
    # @raise [ArgumentError] if either parameter is the wrong type
    def comparable(number1, number2)
      assert_type number1, :Number, :number1
      assert_type number2, :Number, :number2
      bool(number1.comparable_to?(number2))
    end
    declare :comparable, [:number1, :number2]

    # Converts a unitless number to a percentage.
    #
    # @example
    #   percentage(0.2) => 20%
    #   percentage(100px / 50px) => 200%
    # @overload percentage($number)
    #   @param $number [Sass::Script::Value::Number]
    # @return [Sass::Script::Value::Number]
    # @raise [ArgumentError] if `$number` isn't a unitless number
    def percentage(number)
      unless number.is_a?(Sass::Script::Value::Number) && number.unitless?
        raise ArgumentError.new("$number: #{number.inspect} is not a unitless number")
      end
      number(number.value * 100, '%')
    end
    declare :percentage, [:number]

    # Rounds a number to the nearest whole number.
    #
    # @example
    #   round(10.4px) => 10px
    #   round(10.6px) => 11px
    # @overload round($number)
    #   @param $number [Sass::Script::Value::Number]
    # @return [Sass::Script::Value::Number]
    # @raise [ArgumentError] if `$number` isn't a number
    def round(number)
      numeric_transformation(number) {|n| Sass::Util.round(n)}
    end
    declare :round, [:number]

    # Rounds a number up to the next whole number.
    #
    # @example
    #   ceil(10.4px) => 11px
    #   ceil(10.6px) => 11px
    # @overload ceil($number)
    #   @param $number [Sass::Script::Value::Number]
    # @return [Sass::Script::Value::Number]
    # @raise [ArgumentError] if `$number` isn't a number
    def ceil(number)
      numeric_transformation(number) {|n| n.ceil}
    end
    declare :ceil, [:number]

    # Rounds a number down to the previous whole number.
    #
    # @example
    #   floor(10.4px) => 10px
    #   floor(10.6px) => 10px
    # @overload floor($number)
    #   @param $number [Sass::Script::Value::Number]
    # @return [Sass::Script::Value::Number]
    # @raise [ArgumentError] if `$number` isn't a number
    def floor(number)
      numeric_transformation(number) {|n| n.floor}
    end
    declare :floor, [:number]

    # Returns the absolute value of a number.
    #
    # @example
    #   abs(10px) => 10px
    #   abs(-10px) => 10px
    # @overload abs($number)
    #   @param $number [Sass::Script::Value::Number]
    # @return [Sass::Script::Value::Number]
    # @raise [ArgumentError] if `$number` isn't a number
    def abs(number)
      numeric_transformation(number) {|n| n.abs}
    end
    declare :abs, [:number]

    # Finds the minimum of several numbers. This function takes any number of
    # arguments.
    #
    # @example
    #   min(1px, 4px) => 1px
    #   min(5em, 3em, 4em) => 3em
    # @overload min($numbers...)
    #   @param $numbers [[Sass::Script::Value::Number]]
    # @return [Sass::Script::Value::Number]
    # @raise [ArgumentError] if any argument isn't a number, or if not all of
    #   the arguments have comparable units
    def min(*numbers)
      numbers.each {|n| assert_type n, :Number}
      numbers.inject {|min, num| min.lt(num).to_bool ? min : num}
    end
    declare :min, [], :var_args => :true

    # Finds the maximum of several numbers. This function takes any number of
    # arguments.
    #
    # @example
    #   max(1px, 4px) => 4px
    #   max(5em, 3em, 4em) => 5em
    # @overload max($numbers...)
    #   @param $numbers [[Sass::Script::Value::Number]]
    # @return [Sass::Script::Value::Number]
    # @raise [ArgumentError] if any argument isn't a number, or if not all of
    #   the arguments have comparable units
    def max(*values)
      values.each {|v| assert_type v, :Number}
      values.inject {|max, val| max.gt(val).to_bool ? max : val}
    end
    declare :max, [], :var_args => :true

    # Return the length of a list.
    #
    # This can return the number of pairs in a map as well.
    #
    # @example
    #   length(10px) => 1
    #   length(10px 20px 30px) => 3
    #   length((width: 10px, height: 20px)) => 2
    # @overload length($list)
    #   @param $list [Sass::Script::Value::Base]
    # @return [Sass::Script::Value::Number]
    def length(list)
      number(list.to_a.size)
    end
    declare :length, [:list]

    # Return a new list, based on the list provided, but with the nth
    # element changed to the value given.
    #
    # Note that unlike some languages, the first item in a Sass list is number
    # 1, the second number 2, and so forth.
    #
    # Negative index values address elements in reverse order, starting with the last element
    # in the list.
    #
    # @example
    #   set-nth($list: 10px 20px 30px, $n: 2, $value: -20px) => 10px -20px 30px
    # @overload set-nth($list, $n, $value)
    #   @param $list [Sass::Script::Value::Base] The list that will be copied, having the element
    #     at index `$n` changed.
    #   @param $n [Sass::Script::Value::Number] The index of the item to set.
    #     Negative indices count from the end of the list.
    #   @param $value [Sass::Script::Value::Base] The new value at index `$n`.
    # @return [Sass::Script::Value::List]
    # @raise [ArgumentError] if `$n` isn't an integer between 1 and the length
    #   of `$list`
    def set_nth(list, n, value)
      assert_type n, :Number, :n
      Sass::Script::Value::List.assert_valid_index(list, n)
      index = n.to_i > 0 ? n.to_i - 1 : n.to_i
      new_list = list.to_a.dup
      new_list[index] = value
      list.with_contents(new_list)
    end
    declare :set_nth, [:list, :n, :value]

    # Gets the nth item in a list.
    #
    # Note that unlike some languages, the first item in a Sass list is number
    # 1, the second number 2, and so forth.
    #
    # This can return the nth pair in a map as well.
    #
    # Negative index values address elements in reverse order, starting with the last element in
    # the list.
    #
    # @example
    #   nth(10px 20px 30px, 1) => 10px
    #   nth((Helvetica, Arial, sans-serif), 3) => sans-serif
    #   nth((width: 10px, length: 20px), 2) => length, 20px
    # @overload nth($list, $n)
    #   @param $list [Sass::Script::Value::Base]
    #   @param $n [Sass::Script::Value::Number] The index of the item to get.
    #     Negative indices count from the end of the list.
    # @return [Sass::Script::Value::Base]
    # @raise [ArgumentError] if `$n` isn't an integer between 1 and the length
    #   of `$list`
    def nth(list, n)
      assert_type n, :Number, :n
      Sass::Script::Value::List.assert_valid_index(list, n)

      index = n.to_i > 0 ? n.to_i - 1 : n.to_i
      list.to_a[index]
    end
    declare :nth, [:list, :n]

    # Joins together two lists into one.
    #
    # Unless `$separator` is passed, if one list is comma-separated and one is
    # space-separated, the first parameter's separator is used for the resulting
    # list. If both lists have fewer than two items, spaces are used for the
    # resulting list.
    #
    # Unless `$bracketed` is passed, the resulting list is bracketed if the
    # first parameter is.
    #
    # Like all list functions, `join()` returns a new list rather than modifying
    # its arguments in place.
    #
    # @example
    #   join(10px 20px, 30px 40px) => 10px 20px 30px 40px
    #   join((blue, red), (#abc, #def)) => blue, red, #abc, #def
    #   join(10px, 20px) => 10px 20px
    #   join(10px, 20px, comma) => 10px, 20px
    #   join((blue, red), (#abc, #def), space) => blue red #abc #def
    #   join([10px], 20px) => [10px 20px]
    # @overload join($list1, $list2, $separator: auto, $bracketed: auto)
    #   @param $list1 [Sass::Script::Value::Base]
    #   @param $list2 [Sass::Script::Value::Base]
    #   @param $separator [Sass::Script::Value::String] The list separator to use.
    #     If this is `comma` or `space`, that separator will be used. If this is
    #     `auto` (the default), the separator is determined as explained above.
    #   @param $bracketed [Sass::Script::Value::Base] Whether the resulting list
    #     will be bracketed. If this is `auto` (the default), the separator is
    #     determined as explained above.
    # @return [Sass::Script::Value::List]
    def join(list1, list2,
             separator = identifier("auto"), bracketed = identifier("auto"),
             kwargs = nil, *rest)
      if separator.is_a?(Hash)
        kwargs = separator
        separator = identifier("auto")
      elsif bracketed.is_a?(Hash)
        kwargs = bracketed
        bracketed = identifier("auto")
      elsif rest.last.is_a?(Hash)
        rest.unshift kwargs
        kwargs = rest.pop
      end

      unless rest.empty?
        # Add 4 to rest.length because we don't want to count the kwargs hash,
        # which is always passed.
        raise ArgumentError.new("wrong number of arguments (#{rest.length + 4} for 2..4)")
      end

      if kwargs
        separator = kwargs.delete("separator") || separator
        bracketed = kwargs.delete("bracketed") || bracketed

        unless kwargs.empty?
          name, val = kwargs.to_a.first
          raise ArgumentError.new("Unknown argument $#{name} (#{val})")
        end
      end

      assert_type separator, :String, :separator
      unless %w(auto space comma).include?(separator.value)
        raise ArgumentError.new("Separator name must be space, comma, or auto")
      end

      list(list1.to_a + list2.to_a,
        separator:
          if separator.value == 'auto'
            list1.separator || list2.separator || :space
          else
            separator.value.to_sym
          end,
        bracketed:
          if bracketed.is_a?(Sass::Script::Value::String) && bracketed.value == 'auto'
            list1.bracketed
          else
            bracketed.to_bool
          end)
    end
    # We don't actually take variable arguments or keyword arguments, but this
    # is the best way to take either `$separator` or `$bracketed` as keywords
    # without complaining about the other missing.
    declare :join, [:list1, :list2], :var_args => true, :var_kwargs => true

    # Appends a single value onto the end of a list.
    #
    # Unless the `$separator` argument is passed, if the list had only one item,
    # the resulting list will be space-separated.
    #
    # Like all list functions, `append()` returns a new list rather than
    # modifying its argument in place.
    #
    # @example
    #   append(10px 20px, 30px) => 10px 20px 30px
    #   append((blue, red), green) => blue, red, green
    #   append(10px 20px, 30px 40px) => 10px 20px (30px 40px)
    #   append(10px, 20px, comma) => 10px, 20px
    #   append((blue, red), green, space) => blue red green
    # @overload append($list, $val, $separator: auto)
    #   @param $list [Sass::Script::Value::Base]
    #   @param $val [Sass::Script::Value::Base]
    #   @param $separator [Sass::Script::Value::String] The list separator to use.
    #     If this is `comma` or `space`, that separator will be used. If this is
    #     `auto` (the default), the separator is determined as explained above.
    # @return [Sass::Script::Value::List]
    def append(list, val, separator = identifier("auto"))
      assert_type separator, :String, :separator
      unless %w(auto space comma).include?(separator.value)
        raise ArgumentError.new("Separator name must be space, comma, or auto")
      end
      list.with_contents(list.to_a + [val],
        separator:
          if separator.value == 'auto'
            list.separator || :space
          else
            separator.value.to_sym
          end)
    end
    declare :append, [:list, :val]
    declare :append, [:list, :val, :separator]

    # Combines several lists into a single multidimensional list. The nth value
    # of the resulting list is a space separated list of the source lists' nth
    # values.
    #
    # The length of the resulting list is the length of the
    # shortest list.
    #
    # @example
    #   zip(1px 1px 3px, solid dashed solid, red green blue)
    #   => 1px solid red, 1px dashed green, 3px solid blue
    # @overload zip($lists...)
    #   @param $lists [[Sass::Script::Value::Base]]
    # @return [Sass::Script::Value::List]
    def zip(*lists)
      length = nil
      values = []
      lists.each do |list|
        array = list.to_a
        values << array.dup
        length = length.nil? ? array.length : [length, array.length].min
      end
      values.each do |value|
        value.slice!(length)
      end
      new_list_value = values.first.zip(*values[1..-1])
      list(new_list_value.map {|list| list(list, :space)}, :comma)
    end
    declare :zip, [], :var_args => true

    # Returns the position of a value within a list. If the value isn't found,
    # returns `null` instead.
    #
    # Note that unlike some languages, the first item in a Sass list is number
    # 1, the second number 2, and so forth.
    #
    # This can return the position of a pair in a map as well.
    #
    # @example
    #   index(1px solid red, solid) => 2
    #   index(1px solid red, dashed) => null
    #   index((width: 10px, height: 20px), (height 20px)) => 2
    # @overload index($list, $value)
    #   @param $list [Sass::Script::Value::Base]
    #   @param $value [Sass::Script::Value::Base]
    # @return [Sass::Script::Value::Number, Sass::Script::Value::Null] The
    #   1-based index of `$value` in `$list`, or `null`
    def index(list, value)
      index = list.to_a.index {|e| e.eq(value).to_bool}
      index ? number(index + 1) : null
    end
    declare :index, [:list, :value]

    # Returns the separator of a list. If the list doesn't have a separator due
    # to having fewer than two elements, returns `space`.
    #
    # @example
    #   list-separator(1px 2px 3px) => space
    #   list-separator(1px, 2px, 3px) => comma
    #   list-separator('foo') => space
    # @overload list_separator($list)
    #   @param $list [Sass::Script::Value::Base]
    # @return [Sass::Script::Value::String] `comma` or `space`
    def list_separator(list)
      identifier((list.separator || :space).to_s)
    end
    declare :list_separator, [:list]

    # Returns whether a list uses square brackets.
    #
    # @example
    #   is-bracketed(1px 2px 3px) => false
    #   is-bracketed([1px, 2px, 3px]) => true
    # @overload is_bracketed($list)
    #   @param $list [Sass::Script::Value::Base]
    # @return [Sass::Script::Value::Bool]
    def is_bracketed(list)
      bool(list.bracketed)
    end
    declare :is_bracketed, [:list]

    # Returns the value in a map associated with the given key. If the map
    # doesn't have such a key, returns `null`.
    #
    # @example
    #   map-get(("foo": 1, "bar": 2), "foo") => 1
    #   map-get(("foo": 1, "bar": 2), "bar") => 2
    #   map-get(("foo": 1, "bar": 2), "baz") => null
    # @overload map_get($map, $key)
    #   @param $map [Sass::Script::Value::Map]
    #   @param $key [Sass::Script::Value::Base]
    # @return [Sass::Script::Value::Base] The value indexed by `$key`, or `null`
    #   if the map doesn't contain the given key
    # @raise [ArgumentError] if `$map` is not a map
    def map_get(map, key)
      assert_type map, :Map, :map
      map.to_h[key] || null
    end
    declare :map_get, [:map, :key]

    # Merges two maps together into a new map. Keys in `$map2` will take
    # precedence over keys in `$map1`.
    #
    # This is the best way to add new values to a map.
    #
    # All keys in the returned map that also appear in `$map1` will have the
    # same order as in `$map1`. New keys from `$map2` will be placed at the end
    # of the map.
    #
    # Like all map functions, `map-merge()` returns a new map rather than
    # modifying its arguments in place.
    #
    # @example
    #   map-merge(("foo": 1), ("bar": 2)) => ("foo": 1, "bar": 2)
    #   map-merge(("foo": 1, "bar": 2), ("bar": 3)) => ("foo": 1, "bar": 3)
    # @overload map_merge($map1, $map2)
    #   @param $map1 [Sass::Script::Value::Map]
    #   @param $map2 [Sass::Script::Value::Map]
    # @return [Sass::Script::Value::Map]
    # @raise [ArgumentError] if either parameter is not a map
    def map_merge(map1, map2)
      assert_type map1, :Map, :map1
      assert_type map2, :Map, :map2
      map(map1.to_h.merge(map2.to_h))
    end
    declare :map_merge, [:map1, :map2]

    # Returns a new map with keys removed.
    #
    # Like all map functions, `map-merge()` returns a new map rather than
    # modifying its arguments in place.
    #
    # @example
    #   map-remove(("foo": 1, "bar": 2), "bar") => ("foo": 1)
    #   map-remove(("foo": 1, "bar": 2, "baz": 3), "bar", "baz") => ("foo": 1)
    #   map-remove(("foo": 1, "bar": 2), "baz") => ("foo": 1, "bar": 2)
    # @overload map_remove($map, $keys...)
    #   @param $map  [Sass::Script::Value::Map]
    #   @param $keys [[Sass::Script::Value::Base]]
    # @return [Sass::Script::Value::Map]
    # @raise [ArgumentError] if `$map` is not a map
    def map_remove(map, *keys)
      assert_type map, :Map, :map
      hash = map.to_h.dup
      hash.delete_if {|key, _| keys.include?(key)}
      map(hash)
    end
    declare :map_remove, [:map, :key], :var_args => true

    # Returns a list of all keys in a map.
    #
    # @example
    #   map-keys(("foo": 1, "bar": 2)) => "foo", "bar"
    # @overload map_keys($map)
    #   @param $map [Map]
    # @return [List] the list of keys, comma-separated
    # @raise [ArgumentError] if `$map` is not a map
    def map_keys(map)
      assert_type map, :Map, :map
      list(map.to_h.keys, :comma)
    end
    declare :map_keys, [:map]

    # Returns a list of all values in a map. This list may include duplicate
    # values, if multiple keys have the same value.
    #
    # @example
    #   map-values(("foo": 1, "bar": 2)) => 1, 2
    #   map-values(("foo": 1, "bar": 2, "baz": 1)) => 1, 2, 1
    # @overload map_values($map)
    #   @param $map [Map]
    # @return [List] the list of values, comma-separated
    # @raise [ArgumentError] if `$map` is not a map
    def map_values(map)
      assert_type map, :Map, :map
      list(map.to_h.values, :comma)
    end
    declare :map_values, [:map]

    # Returns whether a map has a value associated with a given key.
    #
    # @example
    #   map-has-key(("foo": 1, "bar": 2), "foo") => true
    #   map-has-key(("foo": 1, "bar": 2), "baz") => false
    # @overload map_has_key($map, $key)
    #   @param $map [Sass::Script::Value::Map]
    #   @param $key [Sass::Script::Value::Base]
    # @return [Sass::Script::Value::Bool]
    # @raise [ArgumentError] if `$map` is not a map
    def map_has_key(map, key)
      assert_type map, :Map, :map
      bool(map.to_h.has_key?(key))
    end
    declare :map_has_key, [:map, :key]

    # Returns the map of named arguments passed to a function or mixin that
    # takes a variable argument list. The argument names are strings, and they
    # do not contain the leading `$`.
    #
    # @example
    #   @mixin foo($args...) {
    #     @debug keywords($args); //=> (arg1: val, arg2: val)
    #   }
    #
    #   @include foo($arg1: val, $arg2: val);
    # @overload keywords($args)
    #   @param $args [Sass::Script::Value::ArgList]
    # @return [Sass::Script::Value::Map]
    # @raise [ArgumentError] if `$args` isn't a variable argument list
    def keywords(args)
      assert_type args, :ArgList, :args
      map(Sass::Util.map_keys(args.keywords.as_stored) {|k| Sass::Script::Value::String.new(k)})
    end
    declare :keywords, [:args]

    # Returns one of two values, depending on whether or not `$condition` is
    # true. Just like in `@if`, all values other than `false` and `null` are
    # considered to be true.
    #
    # @example
    #   if(true, 1px, 2px) => 1px
    #   if(false, 1px, 2px) => 2px
    # @overload if($condition, $if-true, $if-false)
    #   @param $condition [Sass::Script::Value::Base] Whether the `$if-true` or
    #     `$if-false` will be returned
    #   @param $if-true [Sass::Script::Tree::Node]
    #   @param $if-false [Sass::Script::Tree::Node]
    # @return [Sass::Script::Value::Base] `$if-true` or `$if-false`
    def if(condition, if_true, if_false)
      if condition.to_bool
        perform(if_true)
      else
        perform(if_false)
      end
    end
    declare :if, [:condition, :"&if_true", :"&if_false"]

    # Returns a unique CSS identifier. The identifier is returned as an unquoted
    # string. The identifier returned is only guaranteed to be unique within the
    # scope of a single Sass run.
    #
    # @overload unique_id()
    # @return [Sass::Script::Value::String]
    def unique_id
      generator = Sass::Script::Functions.random_number_generator
      Thread.current[:sass_last_unique_id] ||= generator.rand(36**8)
      # avoid the temptation of trying to guess the next unique value.
      value = (Thread.current[:sass_last_unique_id] += (generator.rand(10) + 1))
      # the u makes this a legal identifier if it would otherwise start with a number.
      identifier("u" + value.to_s(36).rjust(8, '0'))
    end
    declare :unique_id, []

    # Dynamically calls a function. This can call user-defined
    # functions, built-in functions, or plain CSS functions. It will
    # pass along all arguments, including keyword arguments, to the
    # called function.
    #
    # @example
    #   call(rgb, 10, 100, 255) => #0a64ff
    #   call(scale-color, #0a64ff, $lightness: -10%) => #0058ef
    #
    #   $fn: nth;
    #   call($fn, (a b c), 2) => b
    #
    # @overload call($function, $args...)
    #   @param $function [Sass::Script::Value::Function] The function to call.
    def call(name, *args)
      unless name.is_a?(Sass::Script::Value::String) ||
             name.is_a?(Sass::Script::Value::Function)
        assert_type name, :Function, :function
      end
      if name.is_a?(Sass::Script::Value::String)
        name = if function_exists(name).to_bool
                 get_function(name)
               else
                 get_function(name, "css" => bool(true))
               end
        Sass::Util.sass_warn(<<WARNING)
DEPRECATION WARNING: Passing a string to call() is deprecated and will be illegal
in Sass 4.0. Use call(#{name.to_sass}) instead.
WARNING
      end
      kwargs = args.last.is_a?(Hash) ? args.pop : {}
      funcall = Sass::Script::Tree::Funcall.new(
        name.value,
        args.map {|a| Sass::Script::Tree::Literal.new(a)},
        Sass::Util.map_vals(kwargs) {|v| Sass::Script::Tree::Literal.new(v)},
        nil,
        nil)
      funcall.line = environment.stack.frames.last.line
      funcall.filename = environment.stack.frames.last.filename
      funcall.options = options
      perform(funcall)
    end
    declare :call, [:name], :var_args => true, :var_kwargs => true

    # This function only exists as a workaround for IE7's [`content:
    # counter` bug](http://jes.st/2013/ie7s-css-breaking-content-counter-bug/).
    # It works identically to any other plain-CSS function, except it
    # avoids adding spaces between the argument commas.
    #
    # @example
    #   counter(item, ".") => counter(item,".")
    # @overload counter($args...)
    # @return [Sass::Script::Value::String]
    def counter(*args)
      identifier("counter(#{args.map {|a| a.to_s(options)}.join(',')})")
    end
    declare :counter, [], :var_args => true

    # This function only exists as a workaround for IE7's [`content:
    # counter` bug](http://jes.st/2013/ie7s-css-breaking-content-counter-bug/).
    # It works identically to any other plain-CSS function, except it
    # avoids adding spaces between the argument commas.
    #
    # @example
    #   counters(item, ".") => counters(item,".")
    # @overload counters($args...)
    # @return [Sass::Script::Value::String]
    def counters(*args)
      identifier("counters(#{args.map {|a| a.to_s(options)}.join(',')})")
    end
    declare :counters, [], :var_args => true

    # Check whether a variable with the given name exists in the current
    # scope or in the global scope.
    #
    # @example
    #   $a-false-value: false;
    #   variable-exists(a-false-value) => true
    #   variable-exists(a-null-value) => true
    #
    #   variable-exists(nonexistent) => false
    #
    # @overload variable_exists($name)
    #   @param $name [Sass::Script::Value::String] The name of the variable to
    #     check. The name should not include the `$`.
    # @return [Sass::Script::Value::Bool] Whether the variable is defined in
    #   the current scope.
    def variable_exists(name)
      assert_type name, :String, :name
      bool(environment.caller.var(name.value))
    end
    declare :variable_exists, [:name]

    # Check whether a variable with the given name exists in the global
    # scope (at the top level of the file).
    #
    # @example
    #   $a-false-value: false;
    #   global-variable-exists(a-false-value) => true
    #   global-variable-exists(a-null-value) => true
    #
    #   .foo {
    #     $some-var: false;
    #     @if global-variable-exists(some-var) { /* false, doesn't run */ }
    #   }
    #
    # @overload global_variable_exists($name)
    #   @param $name [Sass::Script::Value::String] The name of the variable to
    #     check. The name should not include the `$`.
    # @return [Sass::Script::Value::Bool] Whether the variable is defined in
    #   the global scope.
    def global_variable_exists(name)
      assert_type name, :String, :name
      bool(environment.global_env.var(name.value))
    end
    declare :global_variable_exists, [:name]

    # Check whether a function with the given name exists.
    #
    # @example
    #   function-exists(lighten) => true
    #
    #   @function myfunc { @return "something"; }
    #   function-exists(myfunc) => true
    #
    # @overload function_exists($name)
    #   @param name [Sass::Script::Value::String] The name of the function to
    #     check or a function reference.
    # @return [Sass::Script::Value::Bool] Whether the function is defined.
    def function_exists(name)
      assert_type name, :String, :name
      exists = Sass::Script::Functions.callable?(name.value.tr("-", "_"))
      exists ||= environment.caller.function(name.value)
      bool(exists)
    end
    declare :function_exists, [:name]

    # Check whether a mixin with the given name exists.
    #
    # @example
    #   mixin-exists(nonexistent) => false
    #
    #   @mixin red-text { color: red; }
    #   mixin-exists(red-text) => true
    #
    # @overload mixin_exists($name)
    #   @param name [Sass::Script::Value::String] The name of the mixin to
    #     check.
    # @return [Sass::Script::Value::Bool] Whether the mixin is defined.
    def mixin_exists(name)
      assert_type name, :String, :name
      bool(environment.mixin(name.value))
    end
    declare :mixin_exists, [:name]

    # Check whether a mixin was passed a content block.
    #
    # Unless `content-exists()` is called directly from a mixin, an error will be raised.
    #
    # @example
    #   @mixin needs-content {
    #     @if not content-exists() {
    #       @error "You must pass a content block!"
    #     }
    #     @content;
    #   }
    #
    # @overload content_exists()
    # @return [Sass::Script::Value::Bool] Whether a content block was passed to the mixin.
    def content_exists
      # frames.last is the stack frame for this function,
      # so we use frames[-2] to get the frame before that.
      mixin_frame = environment.stack.frames[-2]
      unless mixin_frame && mixin_frame.type == :mixin
        raise Sass::SyntaxError.new("Cannot call content-exists() except within a mixin.")
      end
      bool(!environment.caller.content.nil?)
    end
    declare :content_exists, []

    # Return a string containing the value as its Sass representation.
    #
    # @overload inspect($value)
    #   @param $value [Sass::Script::Value::Base] The value to inspect.
    # @return [Sass::Script::Value::String] A representation of the value as
    #   it would be written in Sass.
    def inspect(value)
      value.check_deprecated_interp if value.is_a?(Sass::Script::Value::String)
      unquoted_string(value.to_sass)
    end
    declare :inspect, [:value]

    # @overload random()
    #   Return a decimal between 0 and 1, inclusive of 0 but not 1.
    #   @return [Sass::Script::Value::Number] A decimal value.
    # @overload random($limit)
    #   Return an integer between 1 and `$limit`, inclusive of both 1 and `$limit`.
    #   @param $limit [Sass::Script::Value::Number] The maximum of the random integer to be
    #     returned, a positive integer.
    #   @return [Sass::Script::Value::Number] An integer.
    #   @raise [ArgumentError] if the `$limit` is not 1 or greater
    def random(limit = nil)
      generator = Sass::Script::Functions.random_number_generator
      if limit
        assert_integer limit, "limit"
        if limit.to_i < 1
          raise ArgumentError.new("$limit #{limit} must be greater than or equal to 1")
        end
        number(1 + generator.rand(limit.to_i))
      else
        number(generator.rand)
      end
    end
    declare :random, []
    declare :random, [:limit]

    # Parses a user-provided selector into a list of lists of strings
    # as returned by `&`.
    #
    # @example
    #   selector-parse(".foo .bar, .baz .bang") => ('.foo' '.bar', '.baz' '.bang')
    #
    # @overload selector_parse($selector)
    #   @param $selector [Sass::Script::Value::String, Sass::Script::Value::List]
    #     The selector to parse. This can be either a string, a list of
    #     strings, or a list of lists of strings as returned by `&`.
    #   @return [Sass::Script::Value::List]
    #     A list of lists of strings representing `$selector`. This is
    #     in the same format as a selector returned by `&`.
    def selector_parse(selector)
      parse_selector(selector, :selector).to_sass_script
    end
    declare :selector_parse, [:selector]

    # Return a new selector with all selectors in `$selectors` nested beneath
    # one another as though they had been nested in the stylesheet as
    # `$selector1 { $selector2 { ... } }`.
    #
    # Unlike most selector functions, `selector-nest` allows the
    # parent selector `&` to be used in any selector but the first.
    #
    # @example
    #   selector-nest(".foo", ".bar", ".baz") => .foo .bar .baz
    #   selector-nest(".a .foo", ".b .bar") => .a .foo .b .bar
    #   selector-nest(".foo", "&.bar") => .foo.bar
    #
    # @overload selector_nest($selectors...)
    #   @param $selectors [[Sass::Script::Value::String, Sass::Script::Value::List]]
    #     The selectors to nest. At least one selector must be passed. Each of
    #     these can be either a string, a list of strings, or a list of lists of
    #     strings as returned by `&`.
    #   @return [Sass::Script::Value::List]
    #     A list of lists of strings representing the result of nesting
    #     `$selectors`. This is in the same format as a selector returned by
    #     `&`.
    def selector_nest(*selectors)
      if selectors.empty?
        raise ArgumentError.new("$selectors: At least one selector must be passed")
      end

      parsed = [parse_selector(selectors.first, :selectors)]
      parsed += selectors[1..-1].map {|sel| parse_selector(sel, :selectors, true)}
      parsed.inject {|result, child| child.resolve_parent_refs(result)}.to_sass_script
    end
    declare :selector_nest, [], :var_args => true

    # Return a new selector with all selectors in `$selectors` appended one
    # another as though they had been nested in the stylesheet as `$selector1 {
    # &$selector2 { ... } }`.
    #
    # @example
    #   selector-append(".foo", ".bar", ".baz") => .foo.bar.baz
    #   selector-append(".a .foo", ".b .bar") => "a .foo.b .bar"
    #   selector-append(".foo", "-suffix") => ".foo-suffix"
    #
    # @overload selector_append($selectors...)
    #   @param $selectors [[Sass::Script::Value::String, Sass::Script::Value::List]]
    #     The selectors to append. At least one selector must be passed. Each of
    #     these can be either a string, a list of strings, or a list of lists of
    #     strings as returned by `&`.
    #   @return [Sass::Script::Value::List]
    #     A list of lists of strings representing the result of appending
    #     `$selectors`. This is in the same format as a selector returned by
    #     `&`.
    #   @raise [ArgumentError] if a selector could not be appended.
    def selector_append(*selectors)
      if selectors.empty?
        raise ArgumentError.new("$selectors: At least one selector must be passed")
      end

      selectors.map {|sel| parse_selector(sel, :selectors)}.inject do |parent, child|
        child.members.each do |seq|
          sseq = seq.members.first
          unless sseq.is_a?(Sass::Selector::SimpleSequence)
            raise ArgumentError.new("Can't append \"#{seq}\" to \"#{parent}\"")
          end

          base = sseq.base
          case base
          when Sass::Selector::Universal
            raise ArgumentError.new("Can't append \"#{seq}\" to \"#{parent}\"")
          when Sass::Selector::Element
            unless base.namespace.nil?
              raise ArgumentError.new("Can't append \"#{seq}\" to \"#{parent}\"")
            end
            sseq.members[0] = Sass::Selector::Parent.new(base.name)
          else
            sseq.members.unshift Sass::Selector::Parent.new
          end
        end
        child.resolve_parent_refs(parent)
      end.to_sass_script
    end
    declare :selector_append, [], :var_args => true

    # Returns a new version of `$selector` with `$extendee` extended
    # with `$extender`. This works just like the result of
    #
    #     $selector { ... }
    #     $extender { @extend $extendee }
    #
    # @example
    #   selector-extend(".a .b", ".b", ".foo .bar") => .a .b, .a .foo .bar, .foo .a .bar
    #
    # @overload selector_extend($selector, $extendee, $extender)
    #   @param $selector [Sass::Script::Value::String, Sass::Script::Value::List]
    #     The selector within which `$extendee` is extended with
    #     `$extender`. This can be either a string, a list of strings,
    #     or a list of lists of strings as returned by `&`.
    #   @param $extendee [Sass::Script::Value::String, Sass::Script::Value::List]
    #     The selector being extended. This can be either a string, a
    #     list of strings, or a list of lists of strings as returned
    #     by `&`.
    #   @param $extender [Sass::Script::Value::String, Sass::Script::Value::List]
    #     The selector being injected into `$selector`. This can be
    #     either a string, a list of strings, or a list of lists of
    #     strings as returned by `&`.
    #   @return [Sass::Script::Value::List]
    #     A list of lists of strings representing the result of the
    #     extension. This is in the same format as a selector returned
    #     by `&`.
    #   @raise [ArgumentError] if the extension fails
    def selector_extend(selector, extendee, extender)
      selector = parse_selector(selector, :selector)
      extendee = parse_selector(extendee, :extendee)
      extender = parse_selector(extender, :extender)

      extends = Sass::Util::SubsetMap.new
      begin
        extender.populate_extends(extends, extendee, nil, [], true)
        selector.do_extend(extends).to_sass_script
      rescue Sass::SyntaxError => e
        raise ArgumentError.new(e.to_s)
      end
    end
    declare :selector_extend, [:selector, :extendee, :extender]

    # Replaces all instances of `$original` with `$replacement` in `$selector`
    #
    # This works by using `@extend` and throwing away the original
    # selector. This means that it can be used to do very advanced
    # replacements; see the examples below.
    #
    # @example
    #   selector-replace(".foo .bar", ".bar", ".baz") => ".foo .baz"
    #   selector-replace(".foo.bar.baz", ".foo.baz", ".qux") => ".bar.qux"
    #
    # @overload selector_replace($selector, $original, $replacement)
    #   @param $selector [Sass::Script::Value::String, Sass::Script::Value::List]
    #     The selector within which `$original` is replaced with
    #     `$replacement`. This can be either a string, a list of
    #     strings, or a list of lists of strings as returned by `&`.
    #   @param $original [Sass::Script::Value::String, Sass::Script::Value::List]
    #     The selector being replaced. This can be either a string, a
    #     list of strings, or a list of lists of strings as returned
    #     by `&`.
    #   @param $replacement [Sass::Script::Value::String, Sass::Script::Value::List]
    #     The selector that `$original` is being replaced with. This
    #     can be either a string, a list of strings, or a list of
    #     lists of strings as returned by `&`.
    #   @return [Sass::Script::Value::List]
    #     A list of lists of strings representing the result of the
    #     extension. This is in the same format as a selector returned
    #     by `&`.
    #   @raise [ArgumentError] if the replacement fails
    def selector_replace(selector, original, replacement)
      selector = parse_selector(selector, :selector)
      original = parse_selector(original, :original)
      replacement = parse_selector(replacement, :replacement)

      extends = Sass::Util::SubsetMap.new
      begin
        replacement.populate_extends(extends, original, nil, [], true)
        selector.do_extend(extends, [], true).to_sass_script
      rescue Sass::SyntaxError => e
        raise ArgumentError.new(e.to_s)
      end
    end
    declare :selector_replace, [:selector, :original, :replacement]

    # Unifies two selectors into a single selector that matches only
    # elements matched by both input selectors. Returns `null` if
    # there is no such selector.
    #
    # Like the selector unification done for `@extend`, this doesn't
    # guarantee that the output selector will match *all* elements
    # matched by both input selectors. For example, if `.a .b` is
    # unified with `.x .y`, `.a .x .b.y, .x .a .b.y` will be returned,
    # but `.a.x .b.y` will not. This avoids exponential output size
    # while matching all elements that are likely to exist in
    # practice.
    #
    # @example
    #   selector-unify(".a", ".b") => .a.b
    #   selector-unify(".a .b", ".x .y") => .a .x .b.y, .x .a .b.y
    #   selector-unify(".a.b", ".b.c") => .a.b.c
    #   selector-unify("#a", "#b") => null
    #
    # @overload selector_unify($selector1, $selector2)
    #   @param $selector1 [Sass::Script::Value::String, Sass::Script::Value::List]
    #     The first selector to be unified. This can be either a
    #     string, a list of strings, or a list of lists of strings as
    #     returned by `&`.
    #   @param $selector2 [Sass::Script::Value::String, Sass::Script::Value::List]
    #     The second selector to be unified. This can be either a
    #     string, a list of strings, or a list of lists of strings as
    #     returned by `&`.
    #   @return [Sass::Script::Value::List, Sass::Script::Value::Null]
    #     A list of lists of strings representing the result of the
    #     unification, or null if no unification exists. This is in
    #     the same format as a selector returned by `&`.
    def selector_unify(selector1, selector2)
      selector1 = parse_selector(selector1, :selector1)
      selector2 = parse_selector(selector2, :selector2)
      return null unless (unified = selector1.unify(selector2))
      unified.to_sass_script
    end
    declare :selector_unify, [:selector1, :selector2]

    # Returns the [simple
    # selectors](http://dev.w3.org/csswg/selectors4/#simple) that
    # comprise the compound selector `$selector`.
    #
    # Note that `$selector` **must be** a [compound
    # selector](http://dev.w3.org/csswg/selectors4/#compound). That
    # means it cannot contain commas or spaces. It also means that
    # unlike other selector functions, this takes only strings, not
    # lists.
    #
    # @example
    #   simple-selectors(".foo.bar") => ".foo", ".bar"
    #   simple-selectors(".foo.bar.baz") => ".foo", ".bar", ".baz"
    #
    # @overload simple_selectors($selector)
    #   @param $selector [Sass::Script::Value::String]
    #     The compound selector whose simple selectors will be extracted.
    #   @return [Sass::Script::Value::List]
    #     A list of simple selectors in the compound selector.
    def simple_selectors(selector)
      selector = parse_compound_selector(selector, :selector)
      list(selector.members.map {|simple| unquoted_string(simple.to_s)}, :comma)
    end
    declare :simple_selectors, [:selector]

    # Returns whether `$super` is a superselector of `$sub`. This means that
    # `$super` matches all the elements that `$sub` matches, as well as possibly
    # additional elements. In general, simpler selectors tend to be
    # superselectors of more complex oned.
    #
    # @example
    #   is-superselector(".foo", ".foo.bar") => true
    #   is-superselector(".foo.bar", ".foo") => false
    #   is-superselector(".bar", ".foo .bar") => true
    #   is-superselector(".foo .bar", ".bar") => false
    #
    # @overload is_superselector($super, $sub)
    #   @param $super [Sass::Script::Value::String, Sass::Script::Value::List]
    #     The potential superselector. This can be either a string, a list of
    #     strings, or a list of lists of strings as returned by `&`.
    #   @param $sub [Sass::Script::Value::String, Sass::Script::Value::List]
    #     The potential subselector. This can be either a string, a list of
    #     strings, or a list of lists of strings as returned by `&`.
    #   @return [Sass::Script::Value::Bool]
    #     Whether `$selector1` is a superselector of `$selector2`.
    def is_superselector(sup, sub)
      sup = parse_selector(sup, :super)
      sub = parse_selector(sub, :sub)
      bool(sup.superselector?(sub))
    end
    declare :is_superselector, [:super, :sub]

    private

    # This method implements the pattern of transforming a numeric value into
    # another numeric value with the same units.
    # It yields a number to a block to perform the operation and return a number
    def numeric_transformation(value)
      assert_type value, :Number, :value
      Sass::Script::Value::Number.new(
        yield(value.value), value.numerator_units, value.denominator_units)
    end

    def _adjust(color, amount, attr, range, op, units = "")
      assert_type color, :Color, :color
      assert_type amount, :Number, :amount
      Sass::Util.check_range('Amount', range, amount, units)

      color.with(attr => color.send(attr).send(op, amount.value))
    end

    def percentage_or_unitless(number, max, name)
      if number.unitless?
        number.value
      elsif number.is_unit?("%")
        max * number.value / 100.0;
      else
        raise ArgumentError.new(
          "$#{name}: Expected #{number} to have no units or \"%\"");
      end
    end
  end
end
