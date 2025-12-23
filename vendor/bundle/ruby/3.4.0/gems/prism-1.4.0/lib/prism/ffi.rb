# frozen_string_literal: true
# typed: ignore

# This file is responsible for mirroring the API provided by the C extension by
# using FFI to call into the shared library.

require "rbconfig"
require "ffi"

module Prism
  module LibRubyParser # :nodoc:
    extend FFI::Library

    # Define the library that we will be pulling functions from. Note that this
    # must align with the build shared library from make/rake.
    libprism_in_build = File.expand_path("../../build/libprism.#{RbConfig::CONFIG["SOEXT"]}", __dir__)
    libprism_in_libdir = "#{RbConfig::CONFIG["libdir"]}/prism/libprism.#{RbConfig::CONFIG["SOEXT"]}"

    if File.exist?(libprism_in_build)
      INCLUDE_DIR = File.expand_path("../../include", __dir__)
      ffi_lib libprism_in_build
    else
      INCLUDE_DIR = "#{RbConfig::CONFIG["libdir"]}/prism/include"
      ffi_lib libprism_in_libdir
    end

    # Convert a native C type declaration into a symbol that FFI understands.
    # For example:
    #
    #     const char * -> :pointer
    #     bool         -> :bool
    #     size_t       -> :size_t
    #     void         -> :void
    #
    def self.resolve_type(type, callbacks)
      type = type.strip

      if !type.end_with?("*")
        type.delete_prefix("const ").to_sym
      else
        type = type.delete_suffix("*").rstrip
        callbacks.include?(type.to_sym) ? type.to_sym : :pointer
      end
    end

    # Read through the given header file and find the declaration of each of the
    # given functions. For each one, define a function with the same name and
    # signature as the C function.
    def self.load_exported_functions_from(header, *functions, callbacks)
      File.foreach("#{INCLUDE_DIR}/#{header}") do |line|
        # We only want to attempt to load exported functions.
        next unless line.start_with?("PRISM_EXPORTED_FUNCTION ")

        # We only want to load the functions that we are interested in.
        next unless functions.any? { |function| line.include?(function) }

        # Parse the function declaration.
        unless /^PRISM_EXPORTED_FUNCTION (?<return_type>.+) (?<name>\w+)\((?<arg_types>.+)\);$/ =~ line
          raise "Could not parse #{line}"
        end

        # Delete the function from the list of functions we are looking for to
        # mark it as having been found.
        functions.delete(name)

        # Split up the argument types into an array, ensure we handle the case
        # where there are no arguments (by explicit void).
        arg_types = arg_types.split(",").map(&:strip)
        arg_types = [] if arg_types == %w[void]

        # Resolve the type of the argument by dropping the name of the argument
        # first if it is present.
        arg_types.map! { |type| resolve_type(type.sub(/\w+$/, ""), callbacks) }

        # Attach the function using the FFI library.
        attach_function name, arg_types, resolve_type(return_type, [])
      end

      # If we didn't find all of the functions, raise an error.
      raise "Could not find functions #{functions.inspect}" unless functions.empty?
    end

    callback :pm_parse_stream_fgets_t, [:pointer, :int, :pointer], :pointer
    enum :pm_string_init_result_t, %i[PM_STRING_INIT_SUCCESS PM_STRING_INIT_ERROR_GENERIC PM_STRING_INIT_ERROR_DIRECTORY]
    enum :pm_string_query_t, [:PM_STRING_QUERY_ERROR, -1, :PM_STRING_QUERY_FALSE, :PM_STRING_QUERY_TRUE]

    load_exported_functions_from(
      "prism.h",
      "pm_version",
      "pm_serialize_parse",
      "pm_serialize_parse_stream",
      "pm_serialize_parse_comments",
      "pm_serialize_lex",
      "pm_serialize_parse_lex",
      "pm_parse_success_p",
      "pm_string_query_local",
      "pm_string_query_constant",
      "pm_string_query_method_name",
      [:pm_parse_stream_fgets_t]
    )

    load_exported_functions_from(
      "prism/util/pm_buffer.h",
      "pm_buffer_sizeof",
      "pm_buffer_init",
      "pm_buffer_value",
      "pm_buffer_length",
      "pm_buffer_free",
      []
    )

    load_exported_functions_from(
      "prism/util/pm_string.h",
      "pm_string_mapped_init",
      "pm_string_free",
      "pm_string_source",
      "pm_string_length",
      "pm_string_sizeof",
      []
    )

    # This object represents a pm_buffer_t. We only use it as an opaque pointer,
    # so it doesn't need to know the fields of pm_buffer_t.
    class PrismBuffer # :nodoc:
      SIZEOF = LibRubyParser.pm_buffer_sizeof

      attr_reader :pointer

      def initialize(pointer)
        @pointer = pointer
      end

      def value
        LibRubyParser.pm_buffer_value(pointer)
      end

      def length
        LibRubyParser.pm_buffer_length(pointer)
      end

      def read
        value.read_string(length)
      end

      # Initialize a new buffer and yield it to the block. The buffer will be
      # automatically freed when the block returns.
      def self.with
        FFI::MemoryPointer.new(SIZEOF) do |pointer|
          raise unless LibRubyParser.pm_buffer_init(pointer)
          return yield new(pointer)
        ensure
          LibRubyParser.pm_buffer_free(pointer)
        end
      end
    end

    # This object represents a pm_string_t. We only use it as an opaque pointer,
    # so it doesn't have to be an FFI::Struct.
    class PrismString # :nodoc:
      SIZEOF = LibRubyParser.pm_string_sizeof

      attr_reader :pointer, :length

      def initialize(pointer, length, from_string)
        @pointer = pointer
        @length = length
        @from_string = from_string
      end

      def read
        raise "should use the original String instead" if @from_string
        @pointer.read_string(@length)
      end

      # Yields a pm_string_t pointer to the given block.
      def self.with_string(string)
        raise TypeError unless string.is_a?(String)

        length = string.bytesize
        # + 1 to never get an address of 0, which pm_parser_init() asserts
        FFI::MemoryPointer.new(:char, length + 1, false) do |pointer|
          pointer.write_string(string)
          # since we have the extra byte we might as well \0-terminate
          pointer.put_char(length, 0)
          return yield new(pointer, length, true)
        end
      end

      # Yields a pm_string_t pointer to the given block.
      def self.with_file(filepath)
        raise TypeError unless filepath.is_a?(String)

        # On Windows and Mac, it's expected that filepaths will be encoded in
        # UTF-8. If they are not, we need to convert them to UTF-8 before
        # passing them into pm_string_mapped_init.
        if RbConfig::CONFIG["host_os"].match?(/bccwin|cygwin|djgpp|mingw|mswin|wince|darwin/i) &&
           (encoding = filepath.encoding) != Encoding::ASCII_8BIT && encoding != Encoding::UTF_8
          filepath = filepath.encode(Encoding::UTF_8)
        end

        FFI::MemoryPointer.new(SIZEOF) do |pm_string|
          case (result = LibRubyParser.pm_string_mapped_init(pm_string, filepath))
          when :PM_STRING_INIT_SUCCESS
            pointer = LibRubyParser.pm_string_source(pm_string)
            length = LibRubyParser.pm_string_length(pm_string)
            return yield new(pointer, length, false)
          when :PM_STRING_INIT_ERROR_GENERIC
            raise SystemCallError.new(filepath, FFI.errno)
          when :PM_STRING_INIT_ERROR_DIRECTORY
            raise Errno::EISDIR.new(filepath)
          else
            raise "Unknown error initializing pm_string_t: #{result.inspect}"
          end
        ensure
          LibRubyParser.pm_string_free(pm_string)
        end
      end
    end
  end

  # Mark the LibRubyParser module as private as it should only be called through
  # the prism module.
  private_constant :LibRubyParser

  # The version constant is set by reading the result of calling pm_version.
  VERSION = LibRubyParser.pm_version.read_string

  class << self
    # Mirror the Prism.dump API by using the serialization API.
    def dump(source, **options)
      LibRubyParser::PrismString.with_string(source) { |string| dump_common(string, options) }
    end

    # Mirror the Prism.dump_file API by using the serialization API.
    def dump_file(filepath, **options)
      options[:filepath] = filepath
      LibRubyParser::PrismString.with_file(filepath) { |string| dump_common(string, options) }
    end

    # Mirror the Prism.lex API by using the serialization API.
    def lex(code, **options)
      LibRubyParser::PrismString.with_string(code) { |string| lex_common(string, code, options) }
    end

    # Mirror the Prism.lex_file API by using the serialization API.
    def lex_file(filepath, **options)
      options[:filepath] = filepath
      LibRubyParser::PrismString.with_file(filepath) { |string| lex_common(string, string.read, options) }
    end

    # Mirror the Prism.parse API by using the serialization API.
    def parse(code, **options)
      LibRubyParser::PrismString.with_string(code) { |string| parse_common(string, code, options) }
    end

    # Mirror the Prism.parse_file API by using the serialization API. This uses
    # native strings instead of Ruby strings because it allows us to use mmap
    # when it is available.
    def parse_file(filepath, **options)
      options[:filepath] = filepath
      LibRubyParser::PrismString.with_file(filepath) { |string| parse_common(string, string.read, options) }
    end

    # Mirror the Prism.parse_stream API by using the serialization API.
    def parse_stream(stream, **options)
      LibRubyParser::PrismBuffer.with do |buffer|
        source = +""
        callback = -> (string, size, _) {
          raise "Expected size to be >= 0, got: #{size}" if size <= 0

          if !(line = stream.gets(size - 1)).nil?
            source << line
            string.write_string("#{line}\x00", line.bytesize + 1)
          end
        }

        # In the pm_serialize_parse_stream function it accepts a pointer to the
        # IO object as a void* and then passes it through to the callback as the
        # third argument, but it never touches it itself. As such, since we have
        # access to the IO object already through the closure of the lambda, we
        # can pass a null pointer here and not worry.
        LibRubyParser.pm_serialize_parse_stream(buffer.pointer, nil, callback, dump_options(options))
        Prism.load(source, buffer.read, options.fetch(:freeze, false))
      end
    end

    # Mirror the Prism.parse_comments API by using the serialization API.
    def parse_comments(code, **options)
      LibRubyParser::PrismString.with_string(code) { |string| parse_comments_common(string, code, options) }
    end

    # Mirror the Prism.parse_file_comments API by using the serialization
    # API. This uses native strings instead of Ruby strings because it allows us
    # to use mmap when it is available.
    def parse_file_comments(filepath, **options)
      options[:filepath] = filepath
      LibRubyParser::PrismString.with_file(filepath) { |string| parse_comments_common(string, string.read, options) }
    end

    # Mirror the Prism.parse_lex API by using the serialization API.
    def parse_lex(code, **options)
      LibRubyParser::PrismString.with_string(code) { |string| parse_lex_common(string, code, options) }
    end

    # Mirror the Prism.parse_lex_file API by using the serialization API.
    def parse_lex_file(filepath, **options)
      options[:filepath] = filepath
      LibRubyParser::PrismString.with_file(filepath) { |string| parse_lex_common(string, string.read, options) }
    end

    # Mirror the Prism.parse_success? API by using the serialization API.
    def parse_success?(code, **options)
      LibRubyParser::PrismString.with_string(code) { |string| parse_file_success_common(string, options) }
    end

    # Mirror the Prism.parse_failure? API by using the serialization API.
    def parse_failure?(code, **options)
      !parse_success?(code, **options)
    end

    # Mirror the Prism.parse_file_success? API by using the serialization API.
    def parse_file_success?(filepath, **options)
      options[:filepath] = filepath
      LibRubyParser::PrismString.with_file(filepath) { |string| parse_file_success_common(string, options) }
    end

    # Mirror the Prism.parse_file_failure? API by using the serialization API.
    def parse_file_failure?(filepath, **options)
      !parse_file_success?(filepath, **options)
    end

    # Mirror the Prism.profile API by using the serialization API.
    def profile(source, **options)
      LibRubyParser::PrismString.with_string(source) do |string|
        LibRubyParser::PrismBuffer.with do |buffer|
          LibRubyParser.pm_serialize_parse(buffer.pointer, string.pointer, string.length, dump_options(options))
          nil
        end
      end
    end

    # Mirror the Prism.profile_file API by using the serialization API.
    def profile_file(filepath, **options)
      LibRubyParser::PrismString.with_file(filepath) do |string|
        LibRubyParser::PrismBuffer.with do |buffer|
          options[:filepath] = filepath
          LibRubyParser.pm_serialize_parse(buffer.pointer, string.pointer, string.length, dump_options(options))
          nil
        end
      end
    end

    private

    def dump_common(string, options) # :nodoc:
      LibRubyParser::PrismBuffer.with do |buffer|
        LibRubyParser.pm_serialize_parse(buffer.pointer, string.pointer, string.length, dump_options(options))

        dumped = buffer.read
        dumped.freeze if options.fetch(:freeze, false)

        dumped
      end
    end

    def lex_common(string, code, options) # :nodoc:
      LibRubyParser::PrismBuffer.with do |buffer|
        LibRubyParser.pm_serialize_lex(buffer.pointer, string.pointer, string.length, dump_options(options))
        Serialize.load_lex(code, buffer.read, options.fetch(:freeze, false))
      end
    end

    def parse_common(string, code, options) # :nodoc:
      serialized = dump_common(string, options)
      Serialize.load_parse(code, serialized, options.fetch(:freeze, false))
    end

    def parse_comments_common(string, code, options) # :nodoc:
      LibRubyParser::PrismBuffer.with do |buffer|
        LibRubyParser.pm_serialize_parse_comments(buffer.pointer, string.pointer, string.length, dump_options(options))
        Serialize.load_parse_comments(code, buffer.read, options.fetch(:freeze, false))
      end
    end

    def parse_lex_common(string, code, options) # :nodoc:
      LibRubyParser::PrismBuffer.with do |buffer|
        LibRubyParser.pm_serialize_parse_lex(buffer.pointer, string.pointer, string.length, dump_options(options))
        Serialize.load_parse_lex(code, buffer.read, options.fetch(:freeze, false))
      end
    end

    def parse_file_success_common(string, options) # :nodoc:
      LibRubyParser.pm_parse_success_p(string.pointer, string.length, dump_options(options))
    end

    # Return the value that should be dumped for the command_line option.
    def dump_options_command_line(options)
      command_line = options.fetch(:command_line, "")
      raise ArgumentError, "command_line must be a string" unless command_line.is_a?(String)

      command_line.each_char.inject(0) do |value, char|
        case char
        when "a" then value | 0b000001
        when "e" then value | 0b000010
        when "l" then value | 0b000100
        when "n" then value | 0b001000
        when "p" then value | 0b010000
        when "x" then value | 0b100000
        else raise ArgumentError, "invalid command_line option: #{char}"
        end
      end
    end

    # Return the value that should be dumped for the version option.
    def dump_options_version(version)
      case version
      when nil, "latest"
        0
      when /\A3\.3(\.\d+)?\z/
        1
      when /\A3\.4(\.\d+)?\z/
        2
      when /\A3\.5(\.\d+)?\z/
        0
      else
        raise ArgumentError, "invalid version: #{version}"
      end
    end

    # Convert the given options into a serialized options string.
    def dump_options(options)
      template = +""
      values = []

      template << "L"
      if (filepath = options[:filepath])
        values.push(filepath.bytesize, filepath.b)
        template << "A*"
      else
        values << 0
      end

      template << "l"
      values << options.fetch(:line, 1)

      template << "L"
      if (encoding = options[:encoding])
        name = encoding.is_a?(Encoding) ? encoding.name : encoding
        values.push(name.bytesize, name.b)
        template << "A*"
      else
        values << 0
      end

      template << "C"
      values << (options.fetch(:frozen_string_literal, false) ? 1 : 0)

      template << "C"
      values << dump_options_command_line(options)

      template << "C"
      values << dump_options_version(options[:version])

      template << "C"
      values << (options[:encoding] == false ? 1 : 0)

      template << "C"
      values << (options.fetch(:main_script, false) ? 1 : 0)

      template << "C"
      values << (options.fetch(:partial_script, false) ? 1 : 0)

      template << "C"
      values << (options.fetch(:freeze, false) ? 1 : 0)

      template << "L"
      if (scopes = options[:scopes])
        values << scopes.length

        scopes.each do |scope|
          locals = nil
          forwarding = 0

          case scope
          when Array
            locals = scope
          when Scope
            locals = scope.locals

            scope.forwarding.each do |forward|
              case forward
              when :*     then forwarding |= 0x1
              when :**    then forwarding |= 0x2
              when :&     then forwarding |= 0x4
              when :"..." then forwarding |= 0x8
              else raise ArgumentError, "invalid forwarding value: #{forward}"
              end
            end
          else
            raise TypeError, "wrong argument type #{scope.class.inspect} (expected Array or Prism::Scope)"
          end

          template << "L"
          values << locals.length

          template << "C"
          values << forwarding

          locals.each do |local|
            name = local.name
            template << "L"
            values << name.bytesize

            template << "A*"
            values << name.b
          end
        end
      else
        values << 0
      end

      values.pack(template)
    end
  end

  # Here we are going to patch StringQuery to put in the class-level methods so
  # that it can maintain a consistent interface
  class StringQuery
    class << self
      # Mirrors the C extension's StringQuery::local? method.
      def local?(string)
        query(LibRubyParser.pm_string_query_local(string, string.bytesize, string.encoding.name))
      end

      # Mirrors the C extension's StringQuery::constant? method.
      def constant?(string)
        query(LibRubyParser.pm_string_query_constant(string, string.bytesize, string.encoding.name))
      end

      # Mirrors the C extension's StringQuery::method_name? method.
      def method_name?(string)
        query(LibRubyParser.pm_string_query_method_name(string, string.bytesize, string.encoding.name))
      end

      private

      # Parse the enum result and return an appropriate boolean.
      def query(result)
        case result
        when :PM_STRING_QUERY_ERROR
          raise ArgumentError, "Invalid or non ascii-compatible encoding"
        when :PM_STRING_QUERY_FALSE
          false
        when :PM_STRING_QUERY_TRUE
          true
        end
      end
    end
  end
end
