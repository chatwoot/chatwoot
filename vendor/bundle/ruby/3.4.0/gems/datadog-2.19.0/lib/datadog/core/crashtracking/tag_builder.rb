# frozen_string_literal: true

require_relative '../tag_builder'
require_relative '../utils'

module Datadog
  module Core
    module Crashtracking
      # This module builds a hash of tags
      module TagBuilder
        def self.call(settings)
          hash = Core::TagBuilder.tags(settings).merge(
            'is_crash' => 'true',
          )

          Utils.encode_tags(hash)
        end
      end
    end
  end
end
