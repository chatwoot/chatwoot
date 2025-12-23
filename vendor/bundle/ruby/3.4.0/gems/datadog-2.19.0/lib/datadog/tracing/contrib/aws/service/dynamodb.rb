# frozen_string_literal: true

require_relative './base'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module Aws
        module Service
          # DynamoDB tag handlers.
          class DynamoDB < Base
            def add_tags(span, params)
              table_name = params[:table_name]
              span.set_tag(Aws::Ext::TAG_TABLE_NAME, table_name)
            end
          end
        end
      end
    end
  end
end
