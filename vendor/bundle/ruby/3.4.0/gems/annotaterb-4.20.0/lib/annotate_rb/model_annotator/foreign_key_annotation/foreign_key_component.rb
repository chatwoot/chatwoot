# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module ForeignKeyAnnotation
      class ForeignKeyComponent < Components::Base
        attr_reader :formatted_name, :constraints_info, :ref_info, :max_size

        def initialize(formatted_name, constraints_info, ref_info, max_size)
          @formatted_name = formatted_name
          @constraints_info = constraints_info
          @ref_info = ref_info
          @max_size = max_size
        end

        def to_markdown
          format("# * `%s`%s:\n#     * **`%s`**",
            formatted_name,
            constraints_info.blank? ? "" : " (_#{constraints_info}_)",
            ref_info)
        end

        def to_default
          # standard:disable Lint/FormatParameterMismatch
          format("#  %-#{max_size}.#{max_size}s %s %s",
            formatted_name,
            "(#{ref_info})",
            constraints_info).rstrip
          # standard:enable Lint/FormatParameterMismatch
        end
      end
    end
  end
end
