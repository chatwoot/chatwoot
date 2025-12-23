# frozen_string_literal: true

require_relative './base'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module Aws
        module Service
          # SNS tag handlers.
          class SNS < Base
            def add_tags(span, params)
              topic_arn = params[:topic_arn]
              topic_name = params[:name]
              if topic_arn
                # example topic_arn: arn:aws:sns:us-west-2:123456789012:my-topic-name
                parts = topic_arn.split(':')
                topic_name = parts[-1]
                aws_account = parts[-2]
                span.set_tag(Aws::Ext::TAG_AWS_ACCOUNT, aws_account)
              end
              span.set_tag(Aws::Ext::TAG_TOPIC_NAME, topic_name)
            end
          end
        end
      end
    end
  end
end
