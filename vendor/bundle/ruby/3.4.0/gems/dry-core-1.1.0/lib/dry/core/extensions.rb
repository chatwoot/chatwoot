# frozen_string_literal: true

require "set"

module Dry
  module Core
    # Define extensions that can be later enabled by the user.
    #
    # @example
    #
    #   class Foo
    #     extend Dry::Core::Extensions
    #
    #     register_extension(:bar) do
    #        def bar; :bar end
    #     end
    #   end
    #
    #   Foo.new.bar # => NoMethodError
    #   Foo.load_extensions(:bar)
    #   Foo.new.bar # => :bar
    #
    module Extensions
      # @api private
      def self.extended(obj)
        super
        obj.instance_variable_set(:@__available_extensions__, {})
        obj.instance_variable_set(:@__loaded_extensions__, ::Set.new)
      end

      # Register an extension
      #
      # @param [Symbol] name extension name
      # @yield extension block. This block guaranteed not to be called more than once
      def register_extension(name, &block)
        @__available_extensions__[name] = block
      end

      # Whether an extension is available
      #
      # @param [Symbol] name extension name
      # @return [Boolean] Extension availability
      def available_extension?(name)
        @__available_extensions__.key?(name)
      end

      # Enables specified extensions. Already enabled extensions remain untouched
      #
      # @param [Array<Symbol>] extensions list of extension names
      def load_extensions(*extensions)
        extensions.each do |ext|
          block = @__available_extensions__.fetch(ext) do
            raise ::ArgumentError, "Unknown extension: #{ext.inspect}"
          end
          unless @__loaded_extensions__.include?(ext)
            block.call
            @__loaded_extensions__ << ext
          end
        end
      end
    end
  end
end
