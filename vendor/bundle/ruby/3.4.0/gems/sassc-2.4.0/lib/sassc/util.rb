# frozen_string_literal: true

require "erb"
require "set"
require "enumerator"
require "stringio"
require "rbconfig"
require "uri"
require "thread"
require "pathname"

# A module containing various useful functions.

module SassC::Util

  extend self

  # An array of ints representing the Ruby version number.
  # @api public
  RUBY_VERSION_COMPONENTS = RUBY_VERSION.split(".").map {|s| s.to_i}

  # The Ruby engine we're running under. Defaults to `"ruby"`
  # if the top-level constant is undefined.
  # @api public
  RUBY_ENGINE = defined?(::RUBY_ENGINE) ? ::RUBY_ENGINE : "ruby"

  # Maps the keys in a hash according to a block.
  # @example
  #   map_keys({:foo => "bar", :baz => "bang"}) {|k| k.to_s}
  #     #=> {"foo" => "bar", "baz" => "bang"}
  # @param hash [Hash] The hash to map
  # @yield [key] A block in which the keys are transformed
  # @yieldparam key [Object] The key that should be mapped
  # @yieldreturn [Object] The new value for the key
  # @return [Hash] The mapped hash
  # @see #map_vals
  # @see #map_hash
  def map_keys(hash)
    map_hash(hash) {|k, v| [yield(k), v]}
  end

  # Restricts the numeric `value` to be within `min` and `max`, inclusive.
  # If the value is lower than `min`
  def clamp(value, min, max)
    return min if value < min
    return max if value > max
    return value
  end

  # Like [Fixnum.round], but leaves rooms for slight floating-point
  # differences.
  #
  # @param value [Numeric]
  # @return [Numeric]
  def round(value)
    # If the number is within epsilon of X.5, round up (or down for negative
    # numbers).
    mod = value % 1
    mod_is_half = (mod - 0.5).abs < SassC::Script::Value::Number.epsilon
    if value > 0
      !mod_is_half && mod < 0.5 ? value.floor : value.ceil
    else
      mod_is_half || mod < 0.5 ? value.floor : value.ceil
    end
  end

  # Return an array of all possible paths through the given arrays.
  #
  # @param arrs [Array<Array>]
  # @return [Array<Arrays>]
  #
  # @example
  #   paths([[1, 2], [3, 4], [5]]) #=>
  #     # [[1, 3, 5],
  #     #  [2, 3, 5],
  #     #  [1, 4, 5],
  #     #  [2, 4, 5]]
  def paths(arrs)
    arrs.inject([[]]) do |paths, arr|
      arr.map {|e| paths.map {|path| path + [e]}}.flatten(1)
    end
  end

  # Returns information about the caller of the previous method.
  #
  # @param entry [String] An entry in the `#caller` list, or a similarly formatted string
  # @return [[String, Integer, (String, nil)]]
  #   An array containing the filename, line, and method name of the caller.
  #   The method name may be nil
  def caller_info(entry = nil)
    # JRuby evaluates `caller` incorrectly when it's in an actual default argument.
    entry ||= caller[1]
    info = entry.scan(/^((?:[A-Za-z]:)?.*?):(-?.*?)(?::.*`(.+)')?$/).first
    info[1] = info[1].to_i
    # This is added by Rubinius to designate a block, but we don't care about it.
    info[2].sub!(/ \{\}\Z/, '') if info[2]
    info
  end

  # Throws a NotImplementedError for an abstract method.
  #
  # @param obj [Object] `self`
  # @raise [NotImplementedError]
  def abstract(obj)
    raise NotImplementedError.new("#{obj.class} must implement ##{caller_info[2]}")
  end

  # Prints a deprecation warning for the caller method.
  #
  # @param obj [Object] `self`
  # @param message [String] A message describing what to do instead.
  def deprecated(obj, message = nil)
    obj_class = obj.is_a?(Class) ? "#{obj}." : "#{obj.class}#"
    full_message = "DEPRECATION WARNING: #{obj_class}#{caller_info[2]} " +
      "will be removed in a future version of Sass.#{("\n" + message) if message}"
    SassC::Util.sass_warn full_message
  end

  # Silences all Sass warnings within a block.
  #
  # @yield A block in which no Sass warnings will be printed
  def silence_sass_warnings
    old_level, Sass.logger.log_level = Sass.logger.log_level, :error
    yield
  ensure
    SassC.logger.log_level = old_level
  end

  # The same as `Kernel#warn`, but is silenced by \{#silence\_sass\_warnings}.
  #
  # @param msg [String]
  def sass_warn(msg)
    Sass.logger.warn("#{msg}\n")
  end

  ## Cross Rails Version Compatibility

  # Returns the root of the Rails application,
  # if this is running in a Rails context.
  # Returns `nil` if no such root is defined.
  #
  # @return [String, nil]
  def rails_root
    if defined?(::Rails.root)
      return ::Rails.root.to_s if ::Rails.root
      raise "ERROR: Rails.root is nil!"
    end
    return RAILS_ROOT.to_s if defined?(RAILS_ROOT)
    nil
  end

  # Returns the environment of the Rails application,
  # if this is running in a Rails context.
  # Returns `nil` if no such environment is defined.
  #
  # @return [String, nil]
  def rails_env
    return ::Rails.env.to_s if defined?(::Rails.env)
    return RAILS_ENV.to_s if defined?(RAILS_ENV)
    nil
  end

  ## Cross-OS Compatibility
  #
  # These methods are cached because some of them are called quite frequently
  # and even basic checks like String#== are too costly to be called repeatedly.

  # Whether or not this is running on Windows.
  #
  # @return [Boolean]
  def windows?
    return @windows if defined?(@windows)
    @windows = (RbConfig::CONFIG['host_os'] =~ /mswin|windows|mingw/i)
  end

  # Whether or not this is running on IronRuby.
  #
  # @return [Boolean]
  def ironruby?
    return @ironruby if defined?(@ironruby)
    @ironruby = RUBY_ENGINE == "ironruby"
  end

  # Whether or not this is running on Rubinius.
  #
  # @return [Boolean]
  def rbx?
    return @rbx if defined?(@rbx)
    @rbx = RUBY_ENGINE == "rbx"
  end

  # Whether or not this is running on JRuby.
  #
  # @return [Boolean]
  def jruby?
    return @jruby if defined?(@jruby)
    @jruby = RUBY_PLATFORM =~ /java/
  end

  # Returns an array of ints representing the JRuby version number.
  #
  # @return [Array<Integer>]
  def jruby_version
    @jruby_version ||= ::JRUBY_VERSION.split(".").map {|s| s.to_i}
  end

  # Returns `path` relative to `from`.
  #
  # This is like `Pathname#relative_path_from` except it accepts both strings
  # and pathnames, it handles Windows path separators correctly, and it throws
  # an error rather than crashing if the paths use different encodings
  # (https://github.com/ruby/ruby/pull/713).
  #
  # @param path [String, Pathname]
  # @param from [String, Pathname]
  # @return [Pathname?]
  def relative_path_from(path, from)
    pathname(path.to_s).relative_path_from(pathname(from.to_s))
  rescue NoMethodError => e
    raise e unless e.name == :zero?

    # Work around https://github.com/ruby/ruby/pull/713.
    path = path.to_s
    from = from.to_s
    raise ArgumentError("Incompatible path encodings: #{path.inspect} is #{path.encoding}, " +
      "#{from.inspect} is #{from.encoding}")
  end

  singleton_methods.each {|method| module_function method}

end
