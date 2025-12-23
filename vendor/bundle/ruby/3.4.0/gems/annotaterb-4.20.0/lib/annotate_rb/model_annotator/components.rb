# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    # Shared annotation components
    module Components
      class Base
        # Methods default to #to_default, unless overridden by sub class
        def to_markdown
          to_default
        end

        def to_rdoc
          to_default
        end

        def to_yard
          to_default
        end

        def to_default
          raise NoMethodError, "Not implemented by class #{self.class}"
        end
      end

      class NilComponent < Base
        # Used when we want to return a component, but does not affect annotation generation.
        # It will get ignored when the consuming object calls Array#compact
        def to_default
          nil
        end
      end

      class LineBreak < Base
        def to_default
          ""
        end
      end

      class BlankCommentLine < Base
        def to_default
          "#"
        end
      end

      class Header < Base
        attr_reader :header

        def initialize(header)
          @header = header
        end

        def to_default
          "# #{header}"
        end

        def to_markdown
          "# ### #{header}"
        end
      end
    end
  end
end
