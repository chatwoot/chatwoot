# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class Application < APIResource
    OBJECT_NAME = "application"
    def self.object_name
      "application"
    end

    # Unique identifier for the object.
    attr_reader :id
    # The name of the application.
    attr_reader :name
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Always true for a deleted object
    attr_reader :deleted

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
