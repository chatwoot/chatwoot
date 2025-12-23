# frozen_string_literal: true

require_relative './base'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module Aws
        module Service
          # SQS tag handlers.
          class SQS < Base
            def add_tags(span, params)
              queue_url = params[:queue_url]
              queue_name = params[:queue_name]
              if queue_url
                _, _, _, aws_account, queue_name = queue_url.split('/')
                span.set_tag(Aws::Ext::TAG_AWS_ACCOUNT, aws_account)
              end
              span.set_tag(Aws::Ext::TAG_QUEUE_NAME, queue_name)
            end
          end
        end
      end
    end
  end
end
