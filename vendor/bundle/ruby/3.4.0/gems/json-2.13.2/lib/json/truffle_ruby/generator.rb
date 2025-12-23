# frozen_string_literal: true
module JSON
  module TruffleRuby
    module Generator
      MAP = {
        "\x0" => '\u0000',
        "\x1" => '\u0001',
        "\x2" => '\u0002',
        "\x3" => '\u0003',
        "\x4" => '\u0004',
        "\x5" => '\u0005',
        "\x6" => '\u0006',
        "\x7" => '\u0007',
        "\b"  =>  '\b',
        "\t"  =>  '\t',
        "\n"  =>  '\n',
        "\xb" => '\u000b',
        "\f"  =>  '\f',
        "\r"  =>  '\r',
        "\xe" => '\u000e',
        "\xf" => '\u000f',
        "\x10" => '\u0010',
        "\x11" => '\u0011',
        "\x12" => '\u0012',
        "\x13" => '\u0013',
        "\x14" => '\u0014',
        "\x15" => '\u0015',
        "\x16" => '\u0016',
        "\x17" => '\u0017',
        "\x18" => '\u0018',
        "\x19" => '\u0019',
        "\x1a" => '\u001a',
        "\x1b" => '\u001b',
        "\x1c" => '\u001c',
        "\x1d" => '\u001d',
        "\x1e" => '\u001e',
        "\x1f" => '\u001f',
        '"'   =>  '\"',
        '\\'  =>  '\\\\',
      }.freeze # :nodoc:

      SCRIPT_SAFE_MAP = MAP.merge(
        '/'  =>  '\\/',
        "\u2028" => '\u2028',
        "\u2029" => '\u2029',
      ).freeze

      SCRIPT_SAFE_ESCAPE_PATTERN = /[\/"\\\x0-\x1f\u2028-\u2029]/

      # Convert a UTF8 encoded Ruby string _string_ to a JSON string, encoded with
      # UTF16 big endian characters as \u????, and return it.
      def self.utf8_to_json(string, script_safe = false) # :nodoc:
        if script_safe
          if SCRIPT_SAFE_ESCAPE_PATTERN.match?(string)
            string.gsub(SCRIPT_SAFE_ESCAPE_PATTERN, SCRIPT_SAFE_MAP)
          else
            string
          end
        else
          if /["\\\x0-\x1f]/.match?(string)
            string.gsub(/["\\\x0-\x1f]/, MAP)
          else
            string
          end
        end
      end

      def self.utf8_to_json_ascii(original_string, script_safe = false) # :nodoc:
        string = original_string.b
        map = script_safe ? SCRIPT_SAFE_MAP : MAP
        string.gsub!(/[\/"\\\x0-\x1f]/n) { map[$&] || $& }
        string.gsub!(/(
          (?:
           [\xc2-\xdf][\x80-\xbf]    |
           [\xe0-\xef][\x80-\xbf]{2} |
           [\xf0-\xf4][\x80-\xbf]{3}
          )+ |
          [\x80-\xc1\xf5-\xff]       # invalid
        )/nx) { |c|
          c.size == 1 and raise GeneratorError.new("invalid utf8 byte: '#{c}'", original_string)
          s = c.encode(::Encoding::UTF_16BE, ::Encoding::UTF_8).unpack('H*')[0]
          s.force_encoding(::Encoding::BINARY)
          s.gsub!(/.{4}/n, '\\\\u\&')
          s.force_encoding(::Encoding::UTF_8)
        }
        string.force_encoding(::Encoding::UTF_8)
        string
      rescue => e
        raise GeneratorError.new(e.message, original_string)
      end

      def self.valid_utf8?(string)
        encoding = string.encoding
        (encoding == Encoding::UTF_8 || encoding == Encoding::ASCII) &&
          string.valid_encoding?
      end

      # This class is used to create State instances, that are use to hold data
      # while generating a JSON text from a Ruby data structure.
      class State
        def self.generate(obj, opts = nil, io = nil)
          new(opts).generate(obj, io)
        end

        # Creates a State object from _opts_, which ought to be Hash to create
        # a new State instance configured by _opts_, something else to create
        # an unconfigured instance. If _opts_ is a State object, it is just
        # returned.
        def self.from_state(opts)
          if opts
            case
            when self === opts
              return opts
            when opts.respond_to?(:to_hash)
              return new(opts.to_hash)
            when opts.respond_to?(:to_h)
              return new(opts.to_h)
            end
          end
          new
        end

        # Instantiates a new State object, configured by _opts_.
        #
        # _opts_ can have the following keys:
        #
        # * *indent*: a string used to indent levels (default: ''),
        # * *space*: a string that is put after, a : or , delimiter (default: ''),
        # * *space_before*: a string that is put before a : pair delimiter (default: ''),
        # * *object_nl*: a string that is put at the end of a JSON object (default: ''),
        # * *array_nl*: a string that is put at the end of a JSON array (default: ''),
        # * *script_safe*: true if U+2028, U+2029 and forward slash (/) should be escaped
        #   as to make the JSON object safe to interpolate in a script tag (default: false).
        # * *check_circular*: is deprecated now, use the :max_nesting option instead,
        # * *max_nesting*: sets the maximum level of data structure nesting in
        #   the generated JSON, max_nesting = 0 if no maximum should be checked.
        # * *allow_nan*: true if NaN, Infinity, and -Infinity should be
        #   generated, otherwise an exception is thrown, if these values are
        #   encountered. This options defaults to false.
        def initialize(opts = nil)
          @indent                = ''
          @space                 = ''
          @space_before          = ''
          @object_nl             = ''
          @array_nl              = ''
          @allow_nan             = false
          @ascii_only            = false
          @as_json               = false
          @depth                 = 0
          @buffer_initial_length = 1024
          @script_safe           = false
          @strict                = false
          @max_nesting           = 100
          configure(opts) if opts
        end

        # This string is used to indent levels in the JSON text.
        attr_accessor :indent

        # This string is used to insert a space between the tokens in a JSON
        # string.
        attr_accessor :space

        # This string is used to insert a space before the ':' in JSON objects.
        attr_accessor :space_before

        # This string is put at the end of a line that holds a JSON object (or
        # Hash).
        attr_accessor :object_nl

        # This string is put at the end of a line that holds a JSON array.
        attr_accessor :array_nl

        # This proc converts unsupported types into native JSON types.
        attr_accessor :as_json

        # This integer returns the maximum level of data structure nesting in
        # the generated JSON, max_nesting = 0 if no maximum is checked.
        attr_accessor :max_nesting

        # If this attribute is set to true, forward slashes will be escaped in
        # all json strings.
        attr_accessor :script_safe

        # If this attribute is set to true, attempting to serialize types not
        # supported by the JSON spec will raise a JSON::GeneratorError
        attr_accessor :strict

        # :stopdoc:
        attr_reader :buffer_initial_length

        def buffer_initial_length=(length)
          if length > 0
            @buffer_initial_length = length
          end
        end
        # :startdoc:

        # This integer returns the current depth data structure nesting in the
        # generated JSON.
        attr_accessor :depth

        def check_max_nesting # :nodoc:
          return if @max_nesting.zero?
          current_nesting = depth + 1
          current_nesting > @max_nesting and
            raise NestingError, "nesting of #{current_nesting} is too deep"
        end

        # Returns true, if circular data structures are checked,
        # otherwise returns false.
        def check_circular?
          !@max_nesting.zero?
        end

        # Returns true if NaN, Infinity, and -Infinity should be considered as
        # valid JSON and output.
        def allow_nan?
          @allow_nan
        end

        # Returns true, if only ASCII characters should be generated. Otherwise
        # returns false.
        def ascii_only?
          @ascii_only
        end

        # Returns true, if forward slashes are escaped. Otherwise returns false.
        def script_safe?
          @script_safe
        end

        # Returns true, if strict mode is enabled. Otherwise returns false.
        # Strict mode only allow serializing JSON native types: Hash, Array,
        # String, Integer, Float, true, false and nil.
        def strict?
          @strict
        end

        # Configure this State instance with the Hash _opts_, and return
        # itself.
        def configure(opts)
          if opts.respond_to?(:to_hash)
            opts = opts.to_hash
          elsif opts.respond_to?(:to_h)
            opts = opts.to_h
          else
            raise TypeError, "can't convert #{opts.class} into Hash"
          end
          opts.each do |key, value|
            instance_variable_set "@#{key}", value
          end

          # NOTE: If adding new instance variables here, check whether #generate should check them for #generate_json
          @indent                = opts[:indent]        || '' if opts.key?(:indent)
          @space                 = opts[:space]         || '' if opts.key?(:space)
          @space_before          = opts[:space_before]  || '' if opts.key?(:space_before)
          @object_nl             = opts[:object_nl]     || '' if opts.key?(:object_nl)
          @array_nl              = opts[:array_nl]      || '' if opts.key?(:array_nl)
          @allow_nan             = !!opts[:allow_nan]         if opts.key?(:allow_nan)
          @as_json               = opts[:as_json].to_proc     if opts[:as_json]
          @ascii_only            = opts[:ascii_only]          if opts.key?(:ascii_only)
          @depth                 = opts[:depth] || 0
          @buffer_initial_length ||= opts[:buffer_initial_length]

          @script_safe = if opts.key?(:script_safe)
            !!opts[:script_safe]
          elsif opts.key?(:escape_slash)
            !!opts[:escape_slash]
          else
            false
          end

          @strict                = !!opts[:strict] if opts.key?(:strict)

          if !opts.key?(:max_nesting) # defaults to 100
            @max_nesting = 100
          elsif opts[:max_nesting]
            @max_nesting = opts[:max_nesting]
          else
            @max_nesting = 0
          end
          self
        end
        alias merge configure

        # Returns the configuration instance variables as a hash, that can be
        # passed to the configure method.
        def to_h
          result = {}
          instance_variables.each do |iv|
            iv = iv.to_s[1..-1]
            result[iv.to_sym] = self[iv]
          end
          result
        end

        alias to_hash to_h

        # Generates a valid JSON document from object +obj+ and
        # returns the result. If no valid JSON document can be
        # created this method raises a
        # GeneratorError exception.
        def generate(obj, anIO = nil)
          if @indent.empty? and @space.empty? and @space_before.empty? and @object_nl.empty? and @array_nl.empty? and
              !@ascii_only and !@script_safe and @max_nesting == 0 and (!@strict || Symbol === obj)
            result = generate_json(obj, ''.dup)
          else
            result = obj.to_json(self)
          end
          JSON::TruffleRuby::Generator.valid_utf8?(result) or raise GeneratorError.new(
            "source sequence #{result.inspect} is illegal/malformed utf-8",
            obj
          )
          if anIO
            anIO.write(result)
            anIO
          else
            result
          end
        end

        def generate_new(obj, anIO = nil) # :nodoc:
          dup.generate(obj, anIO)
        end

        # Handles @allow_nan, @buffer_initial_length, other ivars must be the default value (see above)
        private def generate_json(obj, buf)
          case obj
          when Hash
            buf << '{'
            first = true
            obj.each_pair do |k,v|
              buf << ',' unless first

              key_str = k.to_s
              if key_str.class == String
                fast_serialize_string(key_str, buf)
              elsif key_str.is_a?(String)
                generate_json(key_str, buf)
              else
                raise TypeError, "#{k.class}#to_s returns an instance of #{key_str.class}, expected a String"
              end

              buf << ':'
              generate_json(v, buf)
              first = false
            end
            buf << '}'
          when Array
            buf << '['
            first = true
            obj.each do |e|
              buf << ',' unless first
              generate_json(e, buf)
              first = false
            end
            buf << ']'
          when String
            if obj.class == String
              fast_serialize_string(obj, buf)
            else
              buf << obj.to_json(self)
            end
          when Integer
            buf << obj.to_s
          when Symbol
            if @strict
              fast_serialize_string(obj.name, buf)
            else
              buf << obj.to_json(self)
            end
          else
            # Note: Float is handled this way since Float#to_s is slow anyway
            buf << obj.to_json(self)
          end
        end

        # Assumes !@ascii_only, !@script_safe
        private def fast_serialize_string(string, buf) # :nodoc:
          buf << '"'
          unless string.encoding == ::Encoding::UTF_8
            begin
              string = string.encode(::Encoding::UTF_8)
            rescue Encoding::UndefinedConversionError => error
              raise GeneratorError.new(error.message, string)
            end
          end
          raise GeneratorError.new("source sequence is illegal/malformed utf-8", string) unless string.valid_encoding?

          if /["\\\x0-\x1f]/.match?(string)
            buf << string.gsub(/["\\\x0-\x1f]/, MAP)
          else
            buf << string
          end
          buf << '"'
        end

        # Return the value returned by method +name+.
        def [](name)
          if respond_to?(name)
            __send__(name)
          else
            instance_variable_get("@#{name}") if
              instance_variables.include?("@#{name}".to_sym) # avoid warning
          end
        end

        def []=(name, value)
          if respond_to?(name_writer = "#{name}=")
            __send__ name_writer, value
          else
            instance_variable_set "@#{name}", value
          end
        end
      end

      module GeneratorMethods
        module Object
          # Converts this object to a string (calling #to_s), converts
          # it to a JSON string, and returns the result. This is a fallback, if no
          # special method #to_json was defined for some object.
          def to_json(state = nil, *)
            state = State.from_state(state) if state
            if state&.strict?
              value = self
              if state.strict? && !(false == value || true == value || nil == value || String === value || Array === value || Hash === value || Integer === value || Float === value || Fragment === value)
                if state.as_json
                  value = state.as_json.call(value)
                  unless false == value || true == value || nil == value || String === value || Array === value || Hash === value || Integer === value || Float === value || Fragment === value
                    raise GeneratorError.new("#{value.class} returned by #{state.as_json} not allowed in JSON", value)
                  end
                  value.to_json(state)
                else
                  raise GeneratorError.new("#{value.class} not allowed in JSON", value)
                end
              end
            else
              to_s.to_json
            end
          end
        end

        module Hash
          # Returns a JSON string containing a JSON object, that is unparsed from
          # this Hash instance.
          # _state_ is a JSON::State object, that can also be used to configure the
          # produced JSON string output further.
          # _depth_ is used to find out nesting depth, to indent accordingly.
          def to_json(state = nil, *)
            state = State.from_state(state)
            state.check_max_nesting
            json_transform(state)
          end

          private

          def json_shift(state)
            state.object_nl.empty? or return ''
            state.indent * state.depth
          end

          def json_transform(state)
            depth = state.depth += 1

            if empty?
              state.depth -= 1
              return '{}'
            end

            delim = ",#{state.object_nl}"
            result = +"{#{state.object_nl}"
            first = true
            indent = !state.object_nl.empty?
            each { |key, value|
              result << delim unless first
              result << state.indent * depth if indent

              key_str = key.to_s
              if key_str.is_a?(String)
                key_json = key_str.to_json(state)
              else
                raise TypeError, "#{key.class}#to_s returns an instance of #{key_str.class}, expected a String"
              end

              result = +"#{result}#{key_json}#{state.space_before}:#{state.space}"
              if state.strict? && !(false == value || true == value || nil == value || String === value || Array === value || Hash === value || Integer === value || Float === value || Fragment === value)
                if state.as_json
                  value = state.as_json.call(value)
                  unless false == value || true == value || nil == value || String === value || Array === value || Hash === value || Integer === value || Float === value || Fragment === value
                    raise GeneratorError.new("#{value.class} returned by #{state.as_json} not allowed in JSON", value)
                  end
                  result << value.to_json(state)
                else
                  raise GeneratorError.new("#{value.class} not allowed in JSON", value)
                end
              elsif value.respond_to?(:to_json)
                result << value.to_json(state)
              else
                result << %{"#{String(value)}"}
              end
              first = false
            }
            depth = state.depth -= 1
            unless first
              result << state.object_nl
              result << state.indent * depth if indent
            end
            result << '}'
            result
          end
        end

        module Array
          # Returns a JSON string containing a JSON array, that is unparsed from
          # this Array instance.
          # _state_ is a JSON::State object, that can also be used to configure the
          # produced JSON string output further.
          def to_json(state = nil, *)
            state = State.from_state(state)
            state.check_max_nesting
            json_transform(state)
          end

          private

          def json_transform(state)
            depth = state.depth += 1

            if empty?
              state.depth -= 1
              return '[]'
            end

            result = '['.dup
            if state.array_nl.empty?
              delim = ","
            else
              result << state.array_nl
              delim = ",#{state.array_nl}"
            end

            first = true
            indent = !state.array_nl.empty?
            each { |value|
              result << delim unless first
              result << state.indent * depth if indent
              if state.strict? && !(false == value || true == value || nil == value || String === value || Array === value || Hash === value || Integer === value || Float === value || Fragment === value || Symbol == value)
                if state.as_json
                  value = state.as_json.call(value)
                  unless false == value || true == value || nil == value || String === value || Array === value || Hash === value || Integer === value || Float === value || Fragment === value || Symbol === value
                    raise GeneratorError.new("#{value.class} returned by #{state.as_json} not allowed in JSON", value)
                  end
                  result << value.to_json(state)
                else
                  raise GeneratorError.new("#{value.class} not allowed in JSON", value)
                end
              elsif value.respond_to?(:to_json)
                result << value.to_json(state)
              else
                result << %{"#{String(value)}"}
              end
              first = false
            }
            depth = state.depth -= 1
            result << state.array_nl
            result << state.indent * depth if indent
            result << ']'
          end
        end

        module Integer
          # Returns a JSON string representation for this Integer number.
          def to_json(*) to_s end
        end

        module Float
          # Returns a JSON string representation for this Float number.
          def to_json(state = nil, *args)
            state = State.from_state(state)
            if infinite? || nan?
              if state.allow_nan?
                to_s
              elsif state.strict? && state.as_json
                casted_value = state.as_json.call(self)

                if casted_value.equal?(self)
                  raise GeneratorError.new("#{self} not allowed in JSON", self)
                end

                state.check_max_nesting
                state.depth += 1
                result = casted_value.to_json(state, *args)
                state.depth -= 1
                result
              else
                raise GeneratorError.new("#{self} not allowed in JSON", self)
              end
            else
              to_s
            end
          end
        end

        module Symbol
          def to_json(state = nil, *args)
            state = State.from_state(state)
            if state.strict?
              name.to_json(state, *args)
            else
              super
            end
          end
        end

        module String
          # This string should be encoded with UTF-8 A call to this method
          # returns a JSON string encoded with UTF16 big endian characters as
          # \u????.
          def to_json(state = nil, *args)
            state = State.from_state(state)
            if encoding == ::Encoding::UTF_8
              unless valid_encoding?
                raise GeneratorError.new("source sequence is illegal/malformed utf-8", self)
              end
              string = self
            else
              string = encode(::Encoding::UTF_8)
            end
            if state.ascii_only?
              %("#{JSON::TruffleRuby::Generator.utf8_to_json_ascii(string, state.script_safe)}")
            else
              %("#{JSON::TruffleRuby::Generator.utf8_to_json(string, state.script_safe)}")
            end
          rescue Encoding::UndefinedConversionError => error
            raise ::JSON::GeneratorError.new(error.message, self)
          end

          # Module that holds the extending methods if, the String module is
          # included.
          module Extend
            # Raw Strings are JSON Objects (the raw bytes are stored in an
            # array for the key "raw"). The Ruby String can be created by this
            # module method.
            def json_create(o)
              o['raw'].pack('C*')
            end
          end

          # Extends _modul_ with the String::Extend module.
          def self.included(modul)
            modul.extend Extend
          end

          # This method creates a raw object hash, that can be nested into
          # other data structures and will be unparsed as a raw string. This
          # method should be used, if you want to convert raw strings to JSON
          # instead of UTF-8 strings, e. g. binary data.
          def to_json_raw_object
            {
              JSON.create_id  => self.class.name,
              'raw'           => self.unpack('C*'),
            }
          end

          # This method creates a JSON text from the result of
          # a call to to_json_raw_object of this String.
          def to_json_raw(*args)
            to_json_raw_object.to_json(*args)
          end
        end

        module TrueClass
          # Returns a JSON string for true: 'true'.
          def to_json(*) 'true' end
        end

        module FalseClass
          # Returns a JSON string for false: 'false'.
          def to_json(*) 'false' end
        end

        module NilClass
          # Returns a JSON string for nil: 'null'.
          def to_json(*) 'null' end
        end
      end
    end
  end
end
