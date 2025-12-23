# frozen_string_literal: true

module Aws
  module S3
    module Plugins

      # Amazon S3 requires DNS style addressing for buckets outside of
      # the classic region when possible.
      class BucketDns < Seahorse::Client::Plugin

        # When set to `false` DNS compatible bucket names are moved from
        # the request URI path to the host as a subdomain, unless the request
        # is using SSL and the bucket name contains a dot.
        #
        # When set to `true`, the bucket name is always forced to be part
        # of the request URI path.  This will not work with buckets outside
        # the classic region.
        option(:force_path_style,
          default: false,
          doc_type: 'Boolean',
          docstring: <<-DOCS)
When set to `true`, the bucket name is always left in the
request URI and never moved to the host as a sub-domain.
          DOCS

        # These class methods were originally used in a handler in this plugin.
        # SigV2 legacy signer needs this logic so we keep it here as utility.
        # New endpoint resolution will check this as a matcher.
        class << self
          # @param [String] bucket_name
          # @param [Boolean] ssl
          # @return [Boolean]
          def dns_compatible?(bucket_name, ssl)
            if valid_subdomain?(bucket_name)
              bucket_name.match(/\./) && ssl ? false : true
            else
              false
            end
          end

          # @param [String] bucket_name
          # @return [Boolean]
          def valid_subdomain?(bucket_name)
            bucket_name.size < 64 &&
            bucket_name =~ /^[a-z0-9][a-z0-9.-]+[a-z0-9]$/ &&
            bucket_name !~ /(\d+\.){3}\d+/ &&
            bucket_name !~ /[.-]{2}/
          end
        end
      end
    end
  end
end
