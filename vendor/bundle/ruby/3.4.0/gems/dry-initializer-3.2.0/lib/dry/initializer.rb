# frozen_string_literal: true

require "set"

# Namespace for gems in a dry-rb community
module Dry
  #
  # DSL for declaring params and options of class initializers
  #
  module Initializer
    require_relative "initializer/undefined"
    require_relative "initializer/dsl"
    require_relative "initializer/definition"
    require_relative "initializer/builders"
    require_relative "initializer/config"
    require_relative "initializer/mixin"
    require_relative "initializer/dispatchers"

    # Adds methods [.[]] and [.define]
    extend DSL

    # Gem-related configuration
    # @return [Dry::Initializer::Config]
    def dry_initializer
      @dry_initializer ||= Config.new(self)
    end

    # Adds or redefines a parameter of [#dry_initializer]
    # @param  [Symbol]       name
    # @param  [#call, nil]   type (nil)
    # @option opts [Proc]    :default
    # @option opts [Boolean] :optional
    # @option opts [Symbol]  :as
    # @option opts [true, false, :protected, :public, :private] :reader
    # @yield block with nested definition
    # @return [self] itself
    def param(name, type = nil, **opts, &block)
      dry_initializer.param(name, type, **opts, &block)
      self
    end

    # Adds or redefines an option of [#dry_initializer]
    # @param  (see #param)
    # @option (see #param)
    # @yield  (see #param)
    # @return (see #param)
    def option(name, type = nil, **opts, &block)
      dry_initializer.option(name, type, **opts, &block)
      self
    end

    private

    def inherited(klass)
      super
      config = Config.new(klass, null: dry_initializer.null)
      klass.send(:instance_variable_set, :@dry_initializer, config)
      dry_initializer.children << config
    end

    require_relative "initializer/struct"
  end
end
