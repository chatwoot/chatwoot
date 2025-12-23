# frozen_string_literal: true

require "dry/initializer"
require "dry/core/equalizer"

module Dry
  module Schema
    # Processing result
    #
    # @see Processor#call
    #
    # @api public
    class Result
      include ::Dry::Equalizer(:output, :errors)

      extend ::Dry::Initializer[undefined: false]

      # @api private
      param :output, reader: false

      # A list of failure ASTs produced by rule result objects
      #
      # @api private
      option :result_ast, default: -> { EMPTY_ARRAY.dup }

      # @api private
      option :message_compiler

      # @api private
      option :path, optional: true, reader: false

      # @api private
      def self.new(*, **)
        result = super
        yield(result) if block_given?
        result.freeze
      end

      # Return a new result scoped to a specific path
      #
      # @param path [Symbol, Array, Path]
      #
      # @return [Result]
      #
      # @api private
      def at(at_path, &)
        new(@output, path: Path.new([*path, *Path[at_path]]), &)
      end

      # @api private
      def new(output, **opts, &)
        self.class.new(
          output,
          message_compiler: message_compiler,
          result_ast: result_ast,
          **opts,
          &
        )
      end

      # @api private
      def update(hash)
        output.update(hash)
        self
      end

      # @api private
      def path
        @path || Path::EMPTY
      end

      # Dump result to a hash returning processed and validated data
      #
      # @return [Hash]
      #
      # @api private
      def output
        path.equal?(Path::EMPTY) ? @output : @output.dig(*path)
      end
      alias_method :to_h, :output

      # @api private
      def replace(value)
        if value.is_a?(output.class)
          output.replace(value)
        elsif path.equal?(Path::EMPTY)
          @output = value
        else
          value_holder = path.keys.length > 1 ? @output.dig(*path.to_a[0..-2]) : @output

          value_holder[path.last] = value
        end

        self
      end

      # @api private
      def concat(other)
        result_ast.concat(other.map(&:to_ast))
        self
      end

      # Read value from the output hash
      #
      # @param [Symbol] name
      #
      # @return [Object]
      #
      # @api public
      def [](name)
        output[name]
      end

      # Check if a given key is present in the output
      #
      # @param [Symbol] name
      #
      # @return [Boolean]
      #
      # @api public
      def key?(name)
        output.key?(name)
      end

      # Check if there's an error for the provided spec
      #
      # @param [Symbol, Hash<Symbol=>Symbol>] spec
      #
      # @return [Boolean]
      #
      # @api public
      def error?(spec)
        message_set.any? { |msg| Path[msg.path].include?(Path[spec]) }
      end

      # Check if the result is successful
      #
      # @return [Boolean]
      #
      # @api public
      def success?
        result_ast.empty?
      end

      # Check if the result is not successful
      #
      # @return [Boolean]
      #
      # @api public
      def failure?
        !success?
      end

      # Get human-readable error representation
      #
      # @see #message_set
      #
      # @return [MessageSet]
      #
      # @api public
      def errors(options = EMPTY_HASH)
        message_set(options)
      end

      # Return the message set
      #
      # @param [Hash] options
      # @option options [Symbol] :locale Alternative locale (default is :en)
      # @option options [Boolean] :hints Whether to include hint messages or not
      # @option options [Boolean] :full Whether to generate messages that include key names
      #
      # @return [MessageSet]
      #
      # @api public
      def message_set(options = EMPTY_HASH)
        message_compiler.with(options).(result_ast)
      end

      # Return a string representation of the result
      #
      # @return [String]
      #
      # @api public
      def inspect
        "#<#{self.class}#{to_h.inspect} errors=#{errors.to_h.inspect} path=#{path.keys.inspect}>"
      end

      # Pattern matching support
      #
      # @api private
      def deconstruct_keys(_)
        output
      end

      # Add a new error AST node
      #
      # @api private
      def add_error(node)
        result_ast << node
      end
    end
  end
end
