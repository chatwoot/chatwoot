# frozen_string_literal: true

module Seahorse
  module Model
    class Api

      def initialize
        @metadata = {}
        @operations = {}
        @authorizers = {}
        @endpoint_operation = nil
        @require_endpoint_discovery = false
      end

      # @return [String, nil]
      attr_accessor :version

      # @return [Hash]
      attr_accessor :metadata

      # @return [Symbol|nil]
      attr_accessor :endpoint_operation

      # @return [Boolean|nil]
      attr_accessor :require_endpoint_discovery

      def operations(&block)
        if block_given?
          @operations.each(&block)
        else
          @operations.enum_for(:each)
        end
      end

      def operation(name)
        if @operations.key?(name.to_sym)
          @operations[name.to_sym]
        else
          raise ArgumentError, "unknown operation #{name.inspect}"
        end
      end

      def operation_names
        @operations.keys
      end

      def async_operation_names
        @operations.select {|_, op| op.async }.keys
      end

      def add_operation(name, operation)
        @operations[name.to_sym] = operation
      end

      def authorizers(&block)
        if block_given?
          @authorizers.each(&block)
        else
          @authorizers.enum_for(:each)
        end
      end

      def authorizer(name)
        if @authorizers.key?(name.to_sym)
          @authorizers[name.to_sym]
        else
          raise ArgumentError, "unknown authorizer #{name.inspect}"
        end
      end

      def authorizer_names
        @authorizers.keys
      end

      def add_authorizer(name, authorizer)
        @authorizers[name.to_sym] = authorizer
      end

      def inspect(*args)
        "#<#{self.class.name}>"
      end

    end
  end
end
