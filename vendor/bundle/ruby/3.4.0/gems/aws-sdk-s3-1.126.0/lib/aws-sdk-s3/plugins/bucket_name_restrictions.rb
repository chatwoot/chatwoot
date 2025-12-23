# frozen_string_literal: true

module Aws
  module S3
    module Plugins
      # @api private
      class BucketNameRestrictions < Seahorse::Client::Plugin
        class Handler < Seahorse::Client::Handler

          # Useful because Aws::S3::Errors::SignatureDoesNotMatch is thrown
          # when passed a bucket with a forward slash. Instead provide a more
          # helpful error. Ideally should not be a plugin?
          def call(context)
            bucket_member = _bucket_member(context.operation.input.shape)
            if bucket_member && (bucket = context.params[bucket_member])
              if !Aws::ARNParser.arn?(bucket) && bucket.include?('/')
                raise ArgumentError,
                      'bucket name must not contain a forward-slash (/)'
              end
            end
            @handler.call(context)
          end

          private

          def _bucket_member(input)
            input.members.each do |member, ref|
              return member if ref.shape.name == 'BucketName'
            end
            nil
          end

        end

        handler(Handler)

      end
    end
  end
end
