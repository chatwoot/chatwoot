# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module Annotation
      class MarkdownHeader < Components::Base
        MD_NAMES_OVERHEAD = 6
        MD_TYPE_ALLOWANCE = 18

        attr_reader :max_size

        def initialize(max_size)
          @max_size = max_size
        end

        def to_markdown
          name_padding = max_size + MD_NAMES_OVERHEAD
          # standard:disable Lint/FormatParameterMismatch
          formatted_headers = format("# %-#{name_padding}.#{name_padding}s | %-#{MD_TYPE_ALLOWANCE}.#{MD_TYPE_ALLOWANCE}s | %s",
            "Name",
            "Type",
            "Attributes")
          # standard:enable Lint/FormatParameterMismatch

          <<~HEADER.strip
            # ### Columns
            #
            #{formatted_headers}
            # #{"-" * name_padding} | #{"-" * MD_TYPE_ALLOWANCE} | #{"-" * 27}
          HEADER
        end

        def to_default
          nil
        end
      end
    end
  end
end
