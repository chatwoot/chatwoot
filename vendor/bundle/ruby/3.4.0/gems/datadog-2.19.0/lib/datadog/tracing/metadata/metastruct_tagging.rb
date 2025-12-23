# frozen_string_literal: true

require_relative 'metastruct'

module Datadog
  module Tracing
    module Metadata
      # Adds data storage for the `meta_struct` field.
      #
      # This field is used to send more complex data like an array of objects
      # in MessagePack format to the agent, and has no size limitations.
      #
      # The agent fully supports meta_struct from version v7.35.0 (April 2022).
      #
      # On versions older than v7.35.0, sending traces containing meta_struct
      # has no unexpected side-effects; traces are sent to the backend as expected,
      # while the meta_struct field is stripped.
      module MetastructTagging
        # Set the given key / value tag pair on the metastruct.
        #
        # A valid example is:
        #
        #   span.set_metastruct_tag('_dd.stack', [])
        def set_metastruct_tag(key, value)
          metastruct[key] = value
        end

        # Return the metastruct tag value for the given key,
        # returns nil if the key doesn't exist.
        def get_metastruct_tag(key)
          metastruct[key]
        end

        private

        def metastruct
          @metastruct ||= Metastruct.new
        end
      end
    end
  end
end
