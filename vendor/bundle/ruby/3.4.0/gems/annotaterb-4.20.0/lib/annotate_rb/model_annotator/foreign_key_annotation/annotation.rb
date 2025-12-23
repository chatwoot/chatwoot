# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module ForeignKeyAnnotation
      class Annotation
        HEADER_TEXT = "Foreign Keys"

        def initialize(foreign_keys)
          @foreign_keys = foreign_keys
        end

        def body
          [
            Components::BlankCommentLine.new,
            Components::Header.new(HEADER_TEXT),
            Components::BlankCommentLine.new,
            *@foreign_keys
          ]
        end

        def to_markdown
          body.map(&:to_markdown).join("\n")
        end

        def to_default
          body.map(&:to_default).join("\n")
        end
      end
    end
  end
end
