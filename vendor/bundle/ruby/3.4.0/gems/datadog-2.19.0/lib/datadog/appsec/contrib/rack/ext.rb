# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      module Rack
        # Rack integration constants
        module Ext
          COLLECTABLE_REQUEST_HEADERS = [
            'accept',
            'akamai-user-risk',
            'cf-ray',
            'cloudfront-viewer-ja3-fingerprint',
            'content-type',
            'user-agent',
            'x-amzn-trace-Id',
            'x-appgw-trace-id',
            'x-cloud-trace-context',
            'x-sigsci-requestid',
            'x-sigsci-tags'
          ].freeze

          IDENTITY_COLLECTABLE_REQUEST_HEADERS = [
            'accept-encoding',
            'accept-language',
            'cf-connecting-ip',
            'cf-connecting-ipv6',
            'content-encoding',
            'content-language',
            'content-length',
            'fastly-client-ip',
            'forwarded',
            'forwarded-for',
            'host',
            'true-client-ip',
            'via',
            'x-client-ip',
            'x-cluster-client-ip',
            'x-forwarded',
            'x-forwarded-for',
            'x-real-ip'
          ].freeze
        end
      end
    end
  end
end
