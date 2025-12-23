# -*- coding: utf-8 -*-
require 'erb'
require 'set'
require 'enumerator'
require 'stringio'
require 'rbconfig'
require 'uri'
require 'thread'
require 'pathname'

require 'sass/root'
require 'sass/util/subset_map'

module Sass
  # A module containing various useful functions.
  module Util
    extend self

    # An array of ints representing the Ruby version number.
    # @api public
    RUBY_VERSION_COMPONENTS = RUBY_VERSION.split(".").map {|s| s.to_i}

    # The Ruby engine we're running under. Defaults to `"ruby"`
    # if the top-level constant is undefined.
    # @api public
    RUBY_ENGINE = defined?(::RUBY_ENGINE) ? ::RUBY_ENGINE : "ruby"

    # Returns the path of a file relative to the Sass root directory.
    #
    # @param file [String] The filename relative to the Sass root
    # @return [String] The filename relative to the the working directory
    def scope(file)
      File.join(Sass::ROOT_DIR, file)
    end

    # Maps the keys in a hash according to a block.
    #
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

    # Maps the values in a hash according to a block.
    #
    # @example
    #   map_values({:foo => "bar", :baz => "bang"}) {|v| v.to_sym}
    #     #=> {:foo => :bar, :baz => :bang}
    # @param hash [Hash] The hash to map
    # @yield [value] A block in which the values are transformed
    # @yieldparam value [Object] The value that should be mapped
    # @yieldreturn [Object] The new value for the value
    # @return [Hash] The mapped hash
    # @see #map_keys
    # @see #map_hash
    def map_vals(hash)
      # We don't delegate to map_hash for performance here
      # because map_hash does more than is necessary.
      rv = hash.class.new
      hash = hash.as_stored if hash.is_a?(NormalizedMap)
      hash.each do |k, v|
        rv[k] = yield(v)
      end
      rv
    end

    # Maps the key-value pairs of a hash according to a block.
    #
    # @example
    #   map_hash({:foo => "bar", :baz => "bang"}) {|k, v| [k.to_s, v.to_sym]}
    #     #=> {"foo" => :bar, "baz" => :bang}
    # @param hash [Hash] The hash to map
    # @yield [key, value] A block in which the key-value pairs are transformed
    # @yieldparam [key] The hash key
    # @yieldparam [value] The hash value
    # @yieldreturn [(Object, Object)] The new value for the `[key, value]` pair
    # @return [Hash] The mapped hash
    # @see #map_keys
    # @see #map_vals
    def map_hash(hash)
      # Copy and modify is more performant than mapping to an array and using
      # to_hash on the result.
      rv = hash.class.new
      hash.each do |k, v|
        new_key, new_value = yield(k, v)
        new_key = hash.denormalize(new_key) if hash.is_a?(NormalizedMap) && new_key == k
        rv[new_key] = new_value
      end
      rv
    end

    # Computes the powerset of the given array.
    # This is the set of all subsets of the array.
    #
    # @example
    #   powerset([1, 2, 3]) #=>
    #     Set[Set[], Set[1], Set[2], Set[3], Set[1, 2], Set[2, 3], Set[1, 3], Set[1, 2, 3]]
    # @param arr [Enumerable]
    # @return [Set<Set>] The subsets of `arr`
    def powerset(arr)
      arr.inject([Set.new].to_set) do |powerset, el|
        new_powerset = Set.new
        powerset.each do |subset|
          new_powerset << subset
          new_powerset << subset + [el]
        end
        new_powerset
      end
    end

    # Restricts a number to falling within a given range.
    # Returns the number if it falls within the range,
    # or the closest value in the range if it doesn't.
    #
    # @param value [Numeric]
    # @param range [Range<Numeric>]
    # @return [Numeric]
    def restrict(value, range)
      [[value, range.first].max, range.last].min
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
      mod_is_half = (mod - 0.5).abs < Script::Value::Number.epsilon
      if value > 0
        !mod_is_half && mod < 0.5 ? value.floor : value.ceil
      else
        mod_is_half || mod < 0.5 ? value.floor : value.ceil
      end
    end

    # Concatenates all strings that are adjacent in an array,
    # while leaving other elements as they are.
    #
    # @example
    #   merge_adjacent_strings([1, "foo", "bar", 2, "baz"])
    #     #=> [1, "foobar", 2, "baz"]
    # @param arr [Array]
    # @return [Array] The enumerable with strings merged
    def merge_adjacent_strings(arr)
      # Optimize for the common case of one element
      return arr if arr.size < 2
      arr.inject([]) do |a, e|
        if e.is_a?(String)
          if a.last.is_a?(String)
            a.last << e
          else
            a << e.dup
          end
        else
          a << e
        end
        a
      end
    end

    # Non-destructively replaces all occurrences of a subsequence in an array
    # with another subsequence.
    #
    # @example
    #   replace_subseq([1, 2, 3, 4, 5], [2, 3], [:a, :b])
    #     #=> [1, :a, :b, 4, 5]
    #
    # @param arr [Array] The array whose subsequences will be replaced.
    # @param subseq [Array] The subsequence to find and replace.
    # @param replacement [Array] The sequence that `subseq` will be replaced with.
    # @return [Array] `arr` with `subseq` replaced with `replacement`.
    def replace_subseq(arr, subseq, replacement)
      new = []
      matched = []
      i = 0
      arr.each do |elem|
        if elem != subseq[i]
          new.push(*matched)
          matched = []
          i = 0
          new << elem
          next
        end

        if i == subseq.length - 1
          matched = []
          i = 0
          new.push(*replacement)
        else
          matched << elem
          i += 1
        end
      end
      new.push(*matched)
      new
    end

    # Intersperses a value in an enumerable, as would be done with `Array#join`
    # but without concatenating the array together afterwards.
    #
    # @param enum [Enumerable]
    # @param val
    # @return [Array]
    def intersperse(enum, val)
      enum.inject([]) {|a, e| a << e << val}[0...-1]
    end

    def slice_by(enum)
      results = []
      enum.each do |value|
        key = yield(value)
        if !results.empty? && results.last.first == key
          results.last.last << value
        else
          results << [key, [value]]
        end
      end
      results
    end

    # Substitutes a sub-array of one array with another sub-array.
    #
    # @param ary [Array] The array in which to make the substitution
    # @param from [Array] The sequence of elements to replace with `to`
    # @param to [Array] The sequence of elements to replace `from` with
    def substitute(ary, from, to)
      res = ary.dup
      i = 0
      while i < res.size
        if res[i...i + from.size] == from
          res[i...i + from.size] = to
        end
        i += 1
      end
      res
    end

    # Destructively strips whitespace from the beginning and end of the first
    # and last elements, respectively, in the array (if those elements are
    # strings). Preserves CSS escapes at the end of the array.
    #
    # @param arr [Array]
    # @return [Array] `arr`
    def strip_string_array(arr)
      arr.first.lstrip! if arr.first.is_a?(String)
      arr[-1] = Sass::Util.rstrip_except_escapes(arr[-1]) if arr.last.is_a?(String)
      arr
    end

    # Normalizes identifier escapes.
    #
    # See https://github.com/sass/language/blob/master/accepted/identifier-escapes.md.
    #
    # @param ident [String]
    # @return [String]
    def normalize_ident_escapes(ident, start: true)
      ident.gsub(/(^)?(#{Sass::SCSS::RX::ESCAPE})/) do |s|
        at_start = start && $1
        char = escaped_char(s)
        next char if char =~ (at_start ? Sass::SCSS::RX::NMSTART : Sass::SCSS::RX::NMCHAR)
        if char =~ (at_start ? /[\x0-\x1F\x7F0-9]/ : /[\x0-\x1F\x7F]/)
          "\\#{char.ord.to_s(16)} "
        else
          "\\#{char}"
        end
      end
    end

    # Returns the character encoded by the given escape sequence.
    #
    # @param escape [String]
    # @return [String]
    def escaped_char(escape)
      if escape =~ /^\\([0-9a-fA-F]{1,6})[ \t\r\n\f]?/
        $1.to_i(16).chr(Encoding::UTF_8)
      else
        escape[1]
      end
    end

    # Like [String#strip], but preserves escaped whitespace at the end of the
    # string.
    #
    # @param string [String]
    # @return [String]
    def strip_except_escapes(string)
      rstrip_except_escapes(string.lstrip)
    end

    # Like [String#rstrip], but preserves escaped whitespace at the end of the
    # string.
    #
    # @param string [String]
    # @return [String]
    def rstrip_except_escapes(string)
      string.sub(/(?<!\\)\s+$/, '')
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

    # Computes a single longest common subsequence for `x` and `y`.
    # If there are more than one longest common subsequences,
    # the one returned is that which starts first in `x`.
    #
    # @param x [Array]
    # @param y [Array]
    # @yield [a, b] An optional block to use in place of a check for equality
    #   between elements of `x` and `y`.
    # @yieldreturn [Object, nil] If the two values register as equal,
    #   this will return the value to use in the LCS array.
    # @return [Array] The LCS
    def lcs(x, y, &block)
      x = [nil, *x]
      y = [nil, *y]
      block ||= proc {|a, b| a == b && a}
      lcs_backtrace(lcs_table(x, y, &block), x, y, x.size - 1, y.size - 1, &block)
    end

    # Like `String.upcase`, but only ever upcases ASCII letters.
    def upcase(string)
      return string.upcase unless ruby2_4?
      string.upcase(:ascii)
    end

    # Like `String.downcase`, but only ever downcases ASCII letters.
    def downcase(string)
      return string.downcase unless ruby2_4?
      string.downcase(:ascii)
    end

    # Returns a sub-array of `minuend` containing only elements that are also in
    # `subtrahend`. Ensures that the return value has the same order as
    # `minuend`, even on Rubinius where that's not guaranteed by `Array#-`.
    #
    # @param minuend [Array]
    # @param subtrahend [Array]
    # @return [Array]
    def array_minus(minuend, subtrahend)
      return minuend - subtrahend unless rbx?
      set = Set.new(minuend) - subtrahend
      minuend.select {|e| set.include?(e)}
    end

    # Returns the maximum of `val1` and `val2`. We use this over \{Array.max} to
    # avoid unnecessary garbage collection.
    def max(val1, val2)
      val1 > val2 ? val1 : val2
    end

    # Returns the minimum of `val1` and `val2`. We use this over \{Array.min} to
    # avoid unnecessary garbage collection.
    def min(val1, val2)
      val1 <= val2 ? val1 : val2
    end

    # Returns a string description of the character that caused an
    # `Encoding::UndefinedConversionError`.
    #
    # @param e [Encoding::UndefinedConversionError]
    # @return [String]
    def undefined_conversion_error_char(e)
      # Rubinius (as of 2.0.0.rc1) pre-quotes the error character.
      return e.error_char if rbx?
      # JRuby (as of 1.7.2) doesn't have an error_char field on
      # Encoding::UndefinedConversionError.
      return e.error_char.dump unless jruby?
      e.message[/^"[^"]+"/] # "
    end

    # Asserts that `value` falls within `range` (inclusive), leaving
    # room for slight floating-point errors.
    #
    # @param name [String] The name of the value. Used in the error message.
    # @param range [Range] The allowed range of values.
    # @param value [Numeric, Sass::Script::Value::Number] The value to check.
    # @param unit [String] The unit of the value. Used in error reporting.
    # @return [Numeric] `value` adjusted to fall within range, if it
    #   was outside by a floating-point margin.
    def check_range(name, range, value, unit = '')
      grace = (-0.00001..0.00001)
      str = value.to_s
      value = value.value if value.is_a?(Sass::Script::Value::Number)
      return value if range.include?(value)
      return range.first if grace.include?(value - range.first)
      return range.last if grace.include?(value - range.last)
      raise ArgumentError.new(
        "#{name} #{str} must be between #{range.first}#{unit} and #{range.last}#{unit}")
    end

    # Returns whether or not `seq1` is a subsequence of `seq2`. That is, whether
    # or not `seq2` contains every element in `seq1` in the same order (and
    # possibly more elements besides).
    #
    # @param seq1 [Array]
    # @param seq2 [Array]
    # @return [Boolean]
    def subsequence?(seq1, seq2)
      i = j = 0
      loop do
        return true if i == seq1.size
        return false if j == seq2.size
        i += 1 if seq1[i] == seq2[j]
        j += 1
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

    # Returns whether one version string represents a more recent version than another.
    #
    # @param v1 [String] A version string.
    # @param v2 [String] Another version string.
    # @return [Boolean]
    def version_gt(v1, v2)
      # Construct an array to make sure the shorter version is padded with nil
      Array.new([v1.length, v2.length].max).zip(v1.split("."), v2.split(".")) do |_, p1, p2|
        p1 ||= "0"
        p2 ||= "0"
        release1 = p1 =~ /^[0-9]+$/
        release2 = p2 =~ /^[0-9]+$/
        if release1 && release2
          # Integer comparison if both are full releases
          p1, p2 = p1.to_i, p2.to_i
          next if p1 == p2
          return p1 > p2
        elsif !release1 && !release2
          # String comparison if both are prereleases
          next if p1 == p2
          return p1 > p2
        else
          # If only one is a release, that one is newer
          return release1
        end
      end
    end

    # Returns whether one version string represents the same or a more
    # recent version than another.
    #
    # @param v1 [String] A version string.
    # @param v2 [String] Another version string.
    # @return [Boolean]
    def version_geq(v1, v2)
      version_gt(v1, v2) || !version_gt(v2, v1)
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
      Sass::Util.sass_warn full_message
    end

    # Silences all Sass warnings within a block.
    #
    # @yield A block in which no Sass warnings will be printed
    def silence_sass_warnings
      old_level, Sass.logger.log_level = Sass.logger.log_level, :error
      yield
    ensure
      Sass.logger.log_level = old_level
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

    # Returns whether this environment is using ActionPack
    # version 3.0.0 or greater.
    #
    # @return [Boolean]
    def ap_geq_3?
      ap_geq?("3.0.0.beta1")
    end

    # Returns whether this environment is using ActionPack
    # of a version greater than or equal to that specified.
    #
    # @param version [String] The string version number to check against.
    #   Should be greater than or equal to Rails 3,
    #   because otherwise ActionPack::VERSION isn't autoloaded
    # @return [Boolean]
    def ap_geq?(version)
      # The ActionPack module is always loaded automatically in Rails >= 3
      return false unless defined?(ActionPack) && defined?(ActionPack::VERSION) &&
        defined?(ActionPack::VERSION::STRING)

      version_geq(ActionPack::VERSION::STRING, version)
    end

    # Returns an ActionView::Template* class.
    # In pre-3.0 versions of Rails, most of these classes
    # were of the form `ActionView::TemplateFoo`,
    # while afterwards they were of the form `ActionView;:Template::Foo`.
    #
    # @param name [#to_s] The name of the class to get.
    #   For example, `:Error` will return `ActionView::TemplateError`
    #   or `ActionView::Template::Error`.
    def av_template_class(name)
      return ActionView.const_get("Template#{name}") if ActionView.const_defined?("Template#{name}")
      ActionView::Template.const_get(name.to_s)
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

    # Like `Dir.glob`, but works with backslash-separated paths on Windows.
    #
    # @param path [String]
    def glob(path)
      path = path.tr('\\', '/') if windows?
      if block_given?
        Dir.glob(path) {|f| yield(f)}
      else
        Dir.glob(path)
      end
    end

    # Like `Pathname.new`, but normalizes Windows paths to always use backslash
    # separators.
    #
    # `Pathname#relative_path_from` can break if the two pathnames aren't
    # consistent in their slash style.
    #
    # @param path [String]
    # @return [Pathname]
    def pathname(path)
      path = path.tr("/", "\\") if windows?
      Pathname.new(path)
    end

    # Like `Pathname#cleanpath`, but normalizes Windows paths to always use
    # backslash separators. Normally, `Pathname#cleanpath` actually does the
    # reverse -- it will convert backslashes to forward slashes, which can break
    # `Pathname#relative_path_from`.
    #
    # @param path [String, Pathname]
    # @return [Pathname]
    def cleanpath(path)
      path = Pathname.new(path) unless path.is_a?(Pathname)
      pathname(path.cleanpath.to_s)
    end

    # Returns `path` with all symlinks resolved.
    #
    # @param path [String, Pathname]
    # @return [Pathname]
    def realpath(path)
      path = Pathname.new(path) unless path.is_a?(Pathname)

      # Explicitly DON'T run #pathname here. We don't want to convert
      # to Windows directory separators because we're comparing these
      # against the paths returned by Listen, which use forward
      # slashes everywhere.
      begin
        path.realpath
      rescue SystemCallError
        # If [path] doesn't actually exist, don't bail, just
        # return the original.
        path
      end
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

    # Converts `path` to a "file:" URI. This handles Windows paths correctly.
    #
    # @param path [String, Pathname]
    # @return [String]
    def file_uri_from_path(path)
      path = path.to_s if path.is_a?(Pathname)
      path = path.tr('\\', '/') if windows?
      path = URI::DEFAULT_PARSER.escape(path)
      return path.start_with?('/') ? "file://" + path : path unless windows?
      return "file:///" + path.tr("\\", "/") if path =~ %r{^[a-zA-Z]:[/\\]}
      return "file:" + path.tr("\\", "/") if path =~ %r{\\\\[^\\]+\\[^\\/]+}
      path.tr("\\", "/")
    end

    # Retries a filesystem operation if it fails on Windows. Windows
    # has weird and flaky locking rules that can cause operations to fail.
    #
    # @yield [] The filesystem operation.
    def retry_on_windows
      return yield unless windows?

      begin
        yield
      rescue SystemCallError
        sleep 0.1
        yield
      end
    end

    # Prepare a value for a destructuring assignment (e.g. `a, b =
    # val`). This works around a performance bug when using
    # ActiveSupport, and only needs to be called when `val` is likely
    # to be `nil` reasonably often.
    #
    # See [this bug report](http://redmine.ruby-lang.org/issues/4917).
    #
    # @param val [Object]
    # @return [Object]
    def destructure(val)
      val || []
    end

    CHARSET_REGEXP = /\A@charset "([^"]+)"/
    bom = "\uFEFF"
    UTF_8_BOM = bom.encode("UTF-8").force_encoding('BINARY')
    UTF_16BE_BOM = bom.encode("UTF-16BE").force_encoding('BINARY')
    UTF_16LE_BOM = bom.encode("UTF-16LE").force_encoding('BINARY')

    ## Cross-Ruby-Version Compatibility

    # Whether or not this is running under Ruby 2.4 or higher.
    #
    # @return [Boolean]
    def ruby2_4?
      return @ruby2_4 if defined?(@ruby2_4)
      @ruby2_4 =
        if RUBY_VERSION_COMPONENTS[0] == 2
          RUBY_VERSION_COMPONENTS[1] >= 4
        else
          RUBY_VERSION_COMPONENTS[0] > 2
        end
    end

    # Like {\#check\_encoding}, but also checks for a `@charset` declaration
    # at the beginning of the file and uses that encoding if it exists.
    #
    # Sass follows CSS's decoding rules.
    #
    # @param str [String] The string of which to check the encoding
    # @return [(String, Encoding)] The original string encoded as UTF-8,
    #   and the source encoding of the string
    # @raise [Encoding::UndefinedConversionError] if the source encoding
    #   cannot be converted to UTF-8
    # @raise [ArgumentError] if the document uses an unknown encoding with `@charset`
    # @raise [Sass::SyntaxError] If the document declares an encoding that
    #   doesn't match its contents, or it doesn't declare an encoding and its
    #   contents are invalid in the native encoding.
    def check_sass_encoding(str)
      # Determine the fallback encoding following section 3.2 of CSS Syntax Level 3 and Encodings:
      # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#determine-the-fallback-encoding
      # http://encoding.spec.whatwg.org/#decode
      binary = str.dup.force_encoding("BINARY")
      if binary.start_with?(UTF_8_BOM)
        binary.slice! 0, UTF_8_BOM.length
        str = binary.force_encoding('UTF-8')
      elsif binary.start_with?(UTF_16BE_BOM)
        binary.slice! 0, UTF_16BE_BOM.length
        str = binary.force_encoding('UTF-16BE')
      elsif binary.start_with?(UTF_16LE_BOM)
        binary.slice! 0, UTF_16LE_BOM.length
        str = binary.force_encoding('UTF-16LE')
      elsif binary =~ CHARSET_REGEXP
        charset = $1.force_encoding('US-ASCII')
        encoding = Encoding.find(charset)
        if encoding.name == 'UTF-16' || encoding.name == 'UTF-16BE'
          encoding = Encoding.find('UTF-8')
        end
        str = binary.force_encoding(encoding)
      elsif str.encoding.name == "ASCII-8BIT"
        # Normally we want to fall back on believing the Ruby string
        # encoding, but if that's just binary we want to make sure
        # it's valid UTF-8.
        str = str.force_encoding('utf-8')
      end

      find_encoding_error(str) unless str.valid_encoding?

      begin
        # If the string is valid, preprocess it according to section 3.3 of CSS Syntax Level 3.
        return str.encode("UTF-8").gsub(/\r\n?|\f/, "\n").tr("\u0000", "�"), str.encoding
      rescue EncodingError
        find_encoding_error(str)
      end
    end

    # Destructively removes all elements from an array that match a block, and
    # returns the removed elements.
    #
    # @param array [Array] The array from which to remove elements.
    # @yield [el] Called for each element.
    # @yieldparam el [*] The element to test.
    # @yieldreturn [Boolean] Whether or not to extract the element.
    # @return [Array] The extracted elements.
    def extract!(array)
      out = []
      array.reject! do |e|
        next false unless yield e
        out << e
        true
      end
      out
    end

    # Flattens the first level of nested arrays in `arrs`. Unlike
    # `Array#flatten`, this orders the result by taking the first
    # values from each array in order, then the second, and so on.
    #
    # @param arrs [Array] The array to flatten.
    # @return [Array] The flattened array.
    def flatten_vertically(arrs)
      result = []
      arrs = arrs.map {|sub| sub.is_a?(Array) ? sub.dup : Array(sub)}
      until arrs.empty?
        arrs.reject! do |arr|
          result << arr.shift
          arr.empty?
        end
      end
      result
    end

    # Like `Object#inspect`, but preserves non-ASCII characters rather than
    # escaping them under Ruby 1.9.2.  This is necessary so that the
    # precompiled Haml template can be `#encode`d into `@options[:encoding]`
    # before being evaluated.
    #
    # @param obj {Object}
    # @return {String}
    def inspect_obj(obj)
      return obj.inspect unless version_geq(RUBY_VERSION, "1.9.2")
      return ':' + inspect_obj(obj.to_s) if obj.is_a?(Symbol)
      return obj.inspect unless obj.is_a?(String)
      '"' + obj.gsub(/[\x00-\x7F]+/) {|s| s.inspect[1...-1]} + '"'
    end

    # Extracts the non-string vlaues from an array containing both strings and non-strings.
    # These values are replaced with escape sequences.
    # This can be undone using \{#inject\_values}.
    #
    # This is useful e.g. when we want to do string manipulation
    # on an interpolated string.
    #
    # The precise format of the resulting string is not guaranteed.
    # However, it is guaranteed that newlines and whitespace won't be affected.
    #
    # @param arr [Array] The array from which values are extracted.
    # @return [(String, Array)] The resulting string, and an array of extracted values.
    def extract_values(arr)
      values = []
      mapped = arr.map do |e|
        next e.gsub('{', '{{') if e.is_a?(String)
        values << e
        next "{#{values.count - 1}}"
      end
      return mapped.join, values
    end

    # Undoes \{#extract\_values} by transforming a string with escape sequences
    # into an array of strings and non-string values.
    #
    # @param str [String] The string with escape sequences.
    # @param values [Array] The array of values to inject.
    # @return [Array] The array of strings and values.
    def inject_values(str, values)
      return [str.gsub('{{', '{')] if values.empty?
      # Add an extra { so that we process the tail end of the string
      result = (str + '{{').scan(/(.*?)(?:(\{\{)|\{(\d+)\})/m).map do |(pre, esc, n)|
        [pre, esc ? '{' : '', n ? values[n.to_i] : '']
      end.flatten(1)
      result[-2] = '' # Get rid of the extra {
      merge_adjacent_strings(result).reject {|s| s == ''}
    end

    # Allows modifications to be performed on the string form
    # of an array containing both strings and non-strings.
    #
    # @param arr [Array] The array from which values are extracted.
    # @yield [str] A block in which string manipulation can be done to the array.
    # @yieldparam str [String] The string form of `arr`.
    # @yieldreturn [String] The modified string.
    # @return [Array] The modified, interpolated array.
    def with_extracted_values(arr)
      str, vals = extract_values(arr)
      str = yield str
      inject_values(str, vals)
    end

    # Builds a sourcemap file name given the generated CSS file name.
    #
    # @param css [String] The generated CSS file name.
    # @return [String] The source map file name.
    def sourcemap_name(css)
      css + ".map"
    end

    # Escapes certain characters so that the result can be used
    # as the JSON string value. Returns the original string if
    # no escaping is necessary.
    #
    # @param s [String] The string to be escaped
    # @return [String] The escaped string
    def json_escape_string(s)
      return s if s !~ /["\\\b\f\n\r\t]/

      result = ""
      s.split("").each do |c|
        case c
        when '"', "\\"
          result << "\\" << c
        when "\n" then result << "\\n"
        when "\t" then result << "\\t"
        when "\r" then result << "\\r"
        when "\f" then result << "\\f"
        when "\b" then result << "\\b"
        else
          result << c
        end
      end
      result
    end

    # Converts the argument into a valid JSON value.
    #
    # @param v [Integer, String, Array, Boolean, nil]
    # @return [String]
    def json_value_of(v)
      case v
      when Integer
        v.to_s
      when String
        "\"" + json_escape_string(v) + "\""
      when Array
        "[" + v.map {|x| json_value_of(x)}.join(",") + "]"
      when NilClass
        "null"
      when TrueClass
        "true"
      when FalseClass
        "false"
      else
        raise ArgumentError.new("Unknown type: #{v.class.name}")
      end
    end

    VLQ_BASE_SHIFT = 5
    VLQ_BASE = 1 << VLQ_BASE_SHIFT
    VLQ_BASE_MASK = VLQ_BASE - 1
    VLQ_CONTINUATION_BIT = VLQ_BASE

    BASE64_DIGITS = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a + ['+', '/']
    BASE64_DIGIT_MAP = begin
      map = {}
      BASE64_DIGITS.each_with_index.map do |digit, i|
        map[digit] = i
      end
      map
    end

    # Encodes `value` as VLQ (http://en.wikipedia.org/wiki/VLQ).
    #
    # @param value [Integer]
    # @return [String] The encoded value
    def encode_vlq(value)
      if value < 0
        value = ((-value) << 1) | 1
      else
        value <<= 1
      end

      result = ''
      begin
        digit = value & VLQ_BASE_MASK
        value >>= VLQ_BASE_SHIFT
        if value > 0
          digit |= VLQ_CONTINUATION_BIT
        end
        result << BASE64_DIGITS[digit]
      end while value > 0
      result
    end

    ## Static Method Stuff

    # The context in which the ERB for \{#def\_static\_method} will be run.
    class StaticConditionalContext
      # @param set [#include?] The set of variables that are defined for this context.
      def initialize(set)
        @set = set
      end

      # Checks whether or not a variable is defined for this context.
      #
      # @param name [Symbol] The name of the variable
      # @return [Boolean]
      def method_missing(name, *args)
        super unless args.empty? && !block_given?
        @set.include?(name)
      end
    end

    # @private
    ATOMIC_WRITE_MUTEX = Mutex.new

    # This creates a temp file and yields it for writing. When the
    # write is complete, the file is moved into the desired location.
    # The atomicity of this operation is provided by the filesystem's
    # rename operation.
    #
    # @param filename [String] The file to write to.
    # @param perms [Integer] The permissions used for creating this file.
    #   Will be masked by the process umask. Defaults to readable/writeable
    #   by all users however the umask usually changes this to only be writable
    #   by the process's user.
    # @yieldparam tmpfile [Tempfile] The temp file that can be written to.
    # @return The value returned by the block.
    def atomic_create_and_write_file(filename, perms = 0666)
      require 'tempfile'
      tmpfile = Tempfile.new(File.basename(filename), File.dirname(filename))
      tmpfile.binmode if tmpfile.respond_to?(:binmode)
      result = yield tmpfile
      tmpfile.close
      ATOMIC_WRITE_MUTEX.synchronize do
        begin
          File.chmod(perms & ~File.umask, tmpfile.path)
        rescue Errno::EPERM
          # If we don't have permissions to chmod the file, don't let that crash
          # the compilation. See issue 1215.
        end
        File.rename tmpfile.path, filename
      end
      result
    ensure
      # close and remove the tempfile if it still exists,
      # presumably due to an error during write
      tmpfile.close if tmpfile
      tmpfile.unlink if tmpfile
    end

    private

    def find_encoding_error(str)
      encoding = str.encoding
      cr = Regexp.quote("\r".encode(encoding).force_encoding('BINARY'))
      lf = Regexp.quote("\n".encode(encoding).force_encoding('BINARY'))
      ff = Regexp.quote("\f".encode(encoding).force_encoding('BINARY'))
      line_break = /#{cr}#{lf}?|#{ff}|#{lf}/

      str.force_encoding("binary").split(line_break).each_with_index do |line, i|
        begin
          line.encode(encoding)
        rescue Encoding::UndefinedConversionError => e
          raise Sass::SyntaxError.new(
            "Invalid #{encoding.name} character #{undefined_conversion_error_char(e)}",
            :line => i + 1)
        end
      end

      # We shouldn't get here, but it's possible some weird encoding stuff causes it.
      return str, str.encoding
    end

    # Calculates the memoization table for the Least Common Subsequence algorithm.
    # Algorithm from [Wikipedia](http://en.wikipedia.org/wiki/Longest_common_subsequence_problem#Computing_the_length_of_the_LCS)
    def lcs_table(x, y)
      # This method does not take a block as an explicit parameter for performance reasons.
      c = Array.new(x.size) {[]}
      x.size.times {|i| c[i][0] = 0}
      y.size.times {|j| c[0][j] = 0}
      (1...x.size).each do |i|
        (1...y.size).each do |j|
          c[i][j] =
            if yield x[i], y[j]
              c[i - 1][j - 1] + 1
            else
              [c[i][j - 1], c[i - 1][j]].max
            end
        end
      end
      c
    end

    # Computes a single longest common subsequence for arrays x and y.
    # Algorithm from [Wikipedia](http://en.wikipedia.org/wiki/Longest_common_subsequence_problem#Reading_out_an_LCS)
    def lcs_backtrace(c, x, y, i, j, &block)
      return [] if i == 0 || j == 0
      if (v = yield(x[i], y[j]))
        return lcs_backtrace(c, x, y, i - 1, j - 1, &block) << v
      end

      return lcs_backtrace(c, x, y, i, j - 1, &block) if c[i][j - 1] > c[i - 1][j]
      lcs_backtrace(c, x, y, i - 1, j, &block)
    end

    singleton_methods.each {|method| module_function method}
  end
end

require 'sass/util/multibyte_string_scanner'
require 'sass/util/normalized_map'
