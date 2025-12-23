# frozen_string_literal: true

require_relative 'metadata/analytics'
require_relative 'metadata/tagging'
require_relative 'metadata/metastruct_tagging'
require_relative 'metadata/errors'

module Datadog
  module Tracing
    # Adds common tagging behavior
    module Metadata
      def self.included(base)
        base.include(Metadata::Tagging)
        base.include(Metadata::MetastructTagging)
        base.include(Metadata::Errors)

        # Additional extensions
        base.prepend(Metadata::Analytics)
      end
    end
  end
end
