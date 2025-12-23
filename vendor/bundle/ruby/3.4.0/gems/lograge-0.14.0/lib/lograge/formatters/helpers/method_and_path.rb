# frozen_string_literal: true

module Lograge
  module Formatters
    module Helpers
      module MethodAndPath
        def method_and_path_string(data)
          method_and_path = [data[:method], data[:path]].compact
          method_and_path.any?(&:present?) ? " #{method_and_path.join(' ')} " : ' '
        end
      end
    end
  end
end
