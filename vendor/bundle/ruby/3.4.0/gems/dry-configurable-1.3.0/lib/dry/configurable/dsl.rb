# frozen_string_literal: true

module Dry
  module Configurable
    # Setting DSL used by the class API
    #
    # @api private
    class DSL
      VALID_NAME = /\A[a-z_]\w*\z/i

      attr_reader :compiler

      attr_reader :ast

      attr_reader :options

      def initialize(**options, &block)
        @compiler = Compiler.new
        @ast = []
        @options = options
        instance_exec(&block) if block
      end

      # Registers a new setting node and compile it into a setting object
      #
      # @see ClassMethods.setting
      # @api private
      # @return Setting
      def setting(name, **options, &block)
        unless VALID_NAME.match?(name.to_s)
          raise ArgumentError, "#{name} is not a valid setting name"
        end

        ensure_valid_options(options)

        options = {default: default, config_class: config_class, **options}

        node = [:setting, [name.to_sym, options]]

        if block
          ast << [:nested, [node, DSL.new(**@options, &block).ast]]
        else
          ast << node
        end

        compiler.visit(ast.last)
      end

      def config_class
        options[:config_class]
      end

      def default
        options[:default_undefined] ? Undefined : nil
      end

      private

      def ensure_valid_options(options)
        return if options.none?

        invalid_keys = options.keys - Setting::OPTIONS

        raise ArgumentError, "Invalid options: #{invalid_keys.inspect}" unless invalid_keys.empty?
      end

      # Returns a tuple of valid and invalid options hashes derived from the options hash
      # given to the setting
      def valid_and_invalid_options(options)
        options.partition { |k, _| Setting::OPTIONS.include?(k) }.map(&:to_h)
      end
    end
  end
end
