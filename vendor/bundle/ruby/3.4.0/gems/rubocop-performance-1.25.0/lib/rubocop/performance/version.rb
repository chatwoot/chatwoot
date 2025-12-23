# frozen_string_literal: true

module RuboCop
  module Performance
    # This module holds the RuboCop Performance version information.
    module Version
      STRING = '1.25.0'

      def self.document_version
        STRING.match('\d+\.\d+').to_s
      end
    end
  end
end
