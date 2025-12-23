# frozen_string_literal: true

module Dry
  module Schema
    # JSON schema type
    #
    # @see Processor
    # @see Schema#JSON
    #
    # @api public
    class JSON < Processor
      config.key_map_type = :stringified
      config.type_registry_namespace = :json
      config.filter_empty_string = false
    end
  end
end
