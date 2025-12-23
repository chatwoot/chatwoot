# frozen_string_literal: true

module Dry
  module Logic
    module Appliable
      def id
        options[:id]
      end

      def result
        options[:result]
      end

      def applied?
        !result.nil?
      end

      def success?
        result.equal?(true)
      end

      def failure?
        !success?
      end

      def to_ast
        if applied? && id
          [success? ? :success : :failure, [id, ast]]
        else
          ast
        end
      end
    end
  end
end
