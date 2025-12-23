# frozen_string_literal: true

module Datadog
  module Core
    module Utils
      # Helper methods for truncating data
      module Truncation
        module_function

        def truncate_in_middle(string, max_prefix_length, max_suffix_length)
          max_length = max_prefix_length + 3 + max_suffix_length
          if string.length > max_length
            "#{string[0...max_prefix_length]}...#{string[-max_suffix_length..-1]}"
          else
            string
          end
        end
      end
    end
  end
end
