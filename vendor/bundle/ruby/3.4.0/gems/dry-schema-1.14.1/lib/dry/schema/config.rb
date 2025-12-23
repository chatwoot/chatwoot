# frozen_string_literal: true

require "dry/core/equalizer"
require "dry/configurable"
require "dry/schema/constants"

module Dry
  module Schema
    # Schema definition configuration class
    #
    # @see DSL#configure
    #
    # @api public
    class Config
      include ::Dry::Configurable
      include ::Dry::Equalizer(:to_h, inspect: false)

      # @!method predicates
      #
      # Return configured predicate registry
      #
      # @return [Schema::PredicateRegistry]
      #
      # @api public
      setting :predicates, default: PredicateRegistry.new, constructor: -> predicates {
        predicates.is_a?(PredicateRegistry) ? predicates : PredicateRegistry.new(predicates)
      }

      # @!method types
      #
      # Return configured container with extra types
      #
      # @return [Hash]
      #
      # @api public
      setting :types, default: ::Dry::Types

      # @!method messages
      #
      # Return configuration for message backend
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      setting :messages do
        setting :backend, default: :yaml
        setting :namespace
        setting :load_paths, default: ::Set[DEFAULT_MESSAGES_PATH], constructor: :dup.to_proc
        setting :top_namespace, default: DEFAULT_MESSAGES_ROOT
        setting :default_locale
      end

      # @!method validate_keys
      #
      # On/off switch for key validator
      #
      # @return [Boolean]
      #
      # @api public
      setting :validate_keys, default: false

      # @api private
      def respond_to_missing?(meth, include_private = false)
        super || config.respond_to?(meth, include_private)
      end

      # @api private
      def inspect
        "#<#{self.class} #{to_h.map { |k, v| ["#{k}=", v.inspect] }.map(&:join).join(" ")}>"
      end

      private

      # Forward to the underlying config object
      #
      # @api private
      def method_missing(meth, ...)
        super unless config.respond_to?(meth)
        config.public_send(meth, ...)
      end
    end
  end
end
