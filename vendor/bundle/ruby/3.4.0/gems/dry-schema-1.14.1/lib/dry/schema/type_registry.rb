# frozen_string_literal: true

require "dry/schema/constants"
require "dry/schema/types"

module Dry
  module Schema
    # A simple wrapper around Dry::Types registry
    #
    # This is used internally by specialized processor sub-classes
    #
    # @api private
    class TypeRegistry
      # @api private
      attr_reader :types

      # @api private
      attr_reader :namespace

      # @api private
      def self.new(types = ::Dry::Types, namespace = :strict)
        super
      end

      # @api private
      def initialize(types, namespace = :strict)
        @types = types
        @namespace = namespace
      end

      # @api private
      def namespaced(ns)
        self.class.new(types, ns)
      end

      # @api private
      def [](name)
        key = [namespace, name].compact.join(DOT)

        types.registered?(key) ? types[key] : types[name.to_s]
      end
    end
  end
end
