# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Aws
        module Service
          # Base class for all AWS service-specific tag handlers.
          class Base
            def add_tags(span, params); end
          end
        end
      end
    end
  end
end
