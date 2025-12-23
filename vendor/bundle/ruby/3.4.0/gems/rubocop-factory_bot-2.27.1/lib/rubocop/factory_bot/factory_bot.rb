# frozen_string_literal: true

module RuboCop
  # RuboCop factory_bot project namespace
  module FactoryBot
    ATTRIBUTE_DEFINING_METHODS = %i[
      factory
      ignore
      trait
      traits_for_enum
      transient
    ].freeze

    UNPROXIED_METHODS = %i[
      __send__
      __id__
      nil?
      send
      object_id
      extend
      instance_eval
      initialize
      block_given?
      raise
      caller
      method
    ].freeze

    DEFINITION_PROXY_METHODS = %i[
      add_attribute
      after
      association
      before
      callback
      ignore
      initialize_with
      sequence
      skip_create
      to_create
    ].freeze

    RESERVED_METHODS =
      DEFINITION_PROXY_METHODS +
      UNPROXIED_METHODS +
      ATTRIBUTE_DEFINING_METHODS

    private_constant(
      :ATTRIBUTE_DEFINING_METHODS,
      :UNPROXIED_METHODS,
      :DEFINITION_PROXY_METHODS,
      :RESERVED_METHODS
    )

    def self.attribute_defining_methods
      ATTRIBUTE_DEFINING_METHODS
    end

    def self.reserved_methods
      RESERVED_METHODS
    end
  end
end
