# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module Annotation
      class MainHeader < Components::Base
        # Annotate Models plugin use this header
        PREFIX = "== Schema Information"
        PREFIX_MD = "## Schema Information"

        attr_reader :version

        def initialize(version, include_version)
          @version = version
          @include_version = include_version
        end

        def to_markdown
          header = "# #{PREFIX_MD}"
          if @include_version && version > 0
            header += "\n# Schema version: #{version}"
          end

          header
        end

        def to_default
          header = "# #{PREFIX}"
          if @include_version && version > 0
            header += "\n# Schema version: #{version}"
          end

          header
        end
      end
    end
  end
end
