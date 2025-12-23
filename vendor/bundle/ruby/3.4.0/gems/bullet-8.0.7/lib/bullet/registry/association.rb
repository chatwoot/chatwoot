# frozen_string_literal: true

module Bullet
  module Registry
    class Association < Base
      def merge(base, associations)
        @registry.merge!(base => associations)
      end

      def similarly_associated(base, associations)
        @registry.select { |key, value| key.include?(base) && value == associations }
                 .collect(&:first).flatten
      end
    end
  end
end
