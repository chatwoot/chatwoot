# frozen_string_literal: true

require "zeitwerk"

require "dry/core"
require "dry/configurable/constants"
require "dry/configurable/errors"

module Dry
  # @api public
  def self.Configurable(**options)
    Configurable::Extension.new(**options)
  end

  # A simple configuration mixin
  #
  # @example class-level configuration
  #
  #   class App
  #     extend Dry::Configurable
  #
  #     setting :database do
  #       setting :dsn, 'sqlite:memory'
  #     end
  #   end
  #
  #   App.config.database.dsn = 'jdbc:sqlite:memory'
  #   App.config.database.dsn
  #     # => "jdbc:sqlite:memory"
  #
  # @example instance-level configuration
  #
  #   class App
  #     include Dry::Configurable
  #
  #     setting :database
  #   end
  #
  #   production = App.new
  #   production.config.database = ENV['DATABASE_URL']
  #   production.finalize!
  #
  #   development = App.new
  #   development.config.database = 'jdbc:sqlite:memory'
  #   development.finalize!
  #
  # @api public
  module Configurable
    def self.loader
      @loader ||= Zeitwerk::Loader.new.tap do |loader|
        root = File.expand_path("..", __dir__)
        loader.tag = "dry-configurable"
        loader.inflector = Zeitwerk::GemInflector.new("#{root}/dry-configurable.rb")
        loader.push_dir(root)
        loader.ignore(
          "#{root}/dry-configurable.rb",
          "#{root}/dry/configurable/{constants,errors,version}.rb"
        )
        loader.inflector.inflect("dsl" => "DSL")
      end
    end

    # @api private
    def self.extended(klass)
      super
      klass.extend(Extension.new)
    end

    # @api private
    def self.included(klass)
      super
      klass.include(Extension.new)
    end

    loader.setup
  end
end
