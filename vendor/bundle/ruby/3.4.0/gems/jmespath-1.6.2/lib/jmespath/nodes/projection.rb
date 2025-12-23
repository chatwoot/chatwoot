# frozen_string_literal: true
module JMESPath
  # @api private
  module Nodes
    class Projection < Node
      def initialize(target, projection)
        @target = target
        @projection = projection
      end

      def visit(value)
        if (targets = extract_targets(@target.visit(value)))
          list = []
          targets.each do |v|
            vv = @projection.visit(v)
            list << vv unless vv.nil?
          end
          list
        end
      end

      def optimize
        if @projection.is_a?(Current)
          fast_instance
        else
          self.class.new(@target.optimize, @projection.optimize)
        end
      end

      private

      def extract_targets(_left_value)
        nil
      end
    end

    module FastProjector
      def visit(value)
        if (targets = extract_targets(@target.visit(value)))
          targets.compact
        end
      end
    end

    class ArrayProjection < Projection
      def extract_targets(target)
        target.to_ary if target.respond_to?(:to_ary)
      end

      def fast_instance
        FastArrayProjection.new(@target.optimize, @projection.optimize)
      end
    end

    class FastArrayProjection < ArrayProjection
      include FastProjector
    end

    class ObjectProjection < Projection
      def extract_targets(target)
        if target.respond_to?(:to_hash)
          target.to_hash.values
        elsif target.is_a?(Struct)
          target.values
        end
      end

      def fast_instance
        FastObjectProjection.new(@target.optimize, @projection.optimize)
      end
    end

    class FastObjectProjection < ObjectProjection
      include FastProjector
    end
  end
end
