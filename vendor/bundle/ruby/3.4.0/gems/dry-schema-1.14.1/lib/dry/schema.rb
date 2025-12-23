# frozen_string_literal: true

require "zeitwerk"

require "dry/core"
require "dry/configurable"
require "dry/logic"
require "dry/types"

module Dry
  # Main interface
  #
  # @api public
  module Schema
    extend ::Dry::Core::Extensions

    # @api private
    def self.loader
      @loader ||= ::Zeitwerk::Loader.new.tap do |loader|
        root = ::File.expand_path("..", __dir__)
        loader.tag = "dry-schema"
        loader.inflector = ::Zeitwerk::GemInflector.new("#{root}/dry-schema.rb")
        loader.inflector.inflect(
          "dsl" => "DSL",
          "yaml" => "YAML",
          "json" => "JSON",
          "i18n" => "I18n"
        )
        loader.push_dir(root)
        loader.ignore(
          "#{root}/dry-schema.rb",
          "#{root}/dry/schema/{constants,errors,version,extensions}.rb",
          "#{root}/dry/schema/extensions"
        )
        loader.do_not_eager_load("#{root}/dry/schema/messages/i18n.rb")
        loader.inflector.inflect("dsl" => "DSL")
      end
    end

    # Configuration
    #
    # @example
    #   Dry::Schema.config.messages.backend = :i18n
    #
    # @return [Config]
    #
    # @api public
    def self.config
      @config ||= Config.new
    end

    # Define a schema
    #
    # @example
    #   Dry::Schema.define do
    #     required(:name).filled(:string)
    #     required(:age).value(:integer, gt?: 0)
    #   end
    #
    # @param [Hash] options
    #
    # @return [Processor]
    #
    # @see DSL.new
    #
    # @api public
    def self.define(...)
      DSL.new(...).call
    end

    # Define a schema suitable for HTTP params
    #
    # This schema type uses `Types::Params` for coercion by default
    #
    # @example
    #   Dry::Schema.Params do
    #     required(:name).filled(:string)
    #     required(:age).value(:integer, gt?: 0)
    #   end
    #
    # @return [Params]
    #
    # @see Schema#define
    #
    # @api public
    def self.Params(**options, &)
      define(**options, processor_type: Params, &)
    end
    singleton_class.alias_method(:Form, :Params)

    # Define a schema suitable for JSON data
    #
    # This schema type uses `Types::JSON` for coercion by default
    #
    # @example
    #   Dry::Schema.JSON do
    #     required(:name).filled(:string)
    #     required(:age).value(:integer, gt?: 0)
    #   end
    #
    # @return [Params]
    #
    # @see Schema#define
    #
    # @api public
    def self.JSON(**options, &)
      define(**options, processor_type: JSON, &)
    end

    loader.setup
  end
end

require "dry/schema/extensions"
