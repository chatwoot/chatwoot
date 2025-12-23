# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Help methods for file.
      module FileHelp
        def expanded_file_path
          File.expand_path(processed_source.file_path)
        end
      end
    end
  end
end
