# frozen_string_literal: true

module RuboCop
  module Rails
    # This module holds the RuboCop Rails version information.
    module Version
      STRING = '2.32.0'

      def self.document_version
        STRING.match('\d+\.\d+').to_s
      end
    end
  end
end
