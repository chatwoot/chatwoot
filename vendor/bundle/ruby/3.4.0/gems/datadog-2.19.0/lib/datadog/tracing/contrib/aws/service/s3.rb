# frozen_string_literal: true

require_relative './base'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module Aws
        module Service
          # S3 tag handlers.
          class S3 < Base
            def add_tags(span, params)
              bucket_name = params[:bucket]
              span.set_tag(Aws::Ext::TAG_BUCKET_NAME, bucket_name)
            end
          end
        end
      end
    end
  end
end
