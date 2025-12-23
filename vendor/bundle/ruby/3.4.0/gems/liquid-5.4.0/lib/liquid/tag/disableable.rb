# frozen_string_literal: true

module Liquid
  class Tag
    module Disableable
      def render_to_output_buffer(context, output)
        if context.tag_disabled?(tag_name)
          output << disabled_error(context)
          return
        end
        super
      end

      def disabled_error(context)
        # raise then rescue the exception so that the Context#exception_renderer can re-raise it
        raise DisabledError, "#{tag_name} #{parse_context[:locale].t('errors.disabled.tag')}"
      rescue DisabledError => exc
        context.handle_error(exc, line_number)
      end
    end
  end
end
