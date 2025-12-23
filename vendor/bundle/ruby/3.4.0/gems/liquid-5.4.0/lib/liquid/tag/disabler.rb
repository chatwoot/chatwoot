# frozen_string_literal: true

module Liquid
  class Tag
    module Disabler
      module ClassMethods
        attr_reader :disabled_tags
      end

      def self.prepended(base)
        base.extend(ClassMethods)
      end

      def render_to_output_buffer(context, output)
        context.with_disabled_tags(self.class.disabled_tags) do
          super
        end
      end
    end
  end
end
