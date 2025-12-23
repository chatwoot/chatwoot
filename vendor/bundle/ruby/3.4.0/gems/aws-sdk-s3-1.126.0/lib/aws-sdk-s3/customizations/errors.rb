# frozen_string_literal: true

module Aws
  module S3
    module Errors
      # Hijack PermanentRedirect dynamic error to also include endpoint
      # and bucket.
      class PermanentRedirect < ServiceError
        # @param [Seahorse::Client::RequestContext] context
        # @param [String] message
        # @param [Aws::S3::Types::PermanentRedirect] data
        def initialize(context, message, _data = Aws::EmptyStructure.new)
          data = Aws::S3::Types::PermanentRedirect.new(message: message)
          body = context.http_response.body_contents
          if (endpoint = body.match(/<Endpoint>(.+?)<\/Endpoint>/))
            data.endpoint = endpoint[1]
          end
          if (bucket = body.match(/<Bucket>(.+?)<\/Bucket>/))
            data.bucket = bucket[1]
          end
          data.region = context.http_response.headers['x-amz-bucket-region']
          super(context, message, data)
        end
      end
    end
  end
end
