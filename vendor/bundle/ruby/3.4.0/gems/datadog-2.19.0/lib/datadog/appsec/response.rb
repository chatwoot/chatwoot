# frozen_string_literal: true

require_relative 'assets'
require_relative 'utils/http/media_range'

module Datadog
  module AppSec
    # AppSec response
    class Response
      attr_reader :status, :headers, :body

      def initialize(status:, headers: {}, body: [])
        @status = status
        @headers = headers
        @body = body
      end

      def to_rack
        [status, headers, body]
      end

      class << self
        def from_interrupt_params(interrupt_params, http_accept_header)
          return redirect_response(interrupt_params) if interrupt_params['location']

          block_response(interrupt_params, http_accept_header)
        end

        private

        def block_response(interrupt_params, http_accept_header)
          content_type = case interrupt_params['type']
          when nil, 'auto' then content_type(http_accept_header)
          else FORMAT_TO_CONTENT_TYPE.fetch(interrupt_params['type'], DEFAULT_CONTENT_TYPE)
          end

          Response.new(
            status: interrupt_params['status_code']&.to_i || 403,
            headers: {'Content-Type' => content_type},
            body: [content(content_type)],
          )
        end

        def redirect_response(interrupt_params)
          status_code = interrupt_params['status_code'].to_i

          Response.new(
            status: ((status_code >= 300 && status_code < 400) ? status_code : 303),
            headers: {'Location' => interrupt_params.fetch('location')},
            body: [],
          )
        end

        CONTENT_TYPE_TO_FORMAT = {
          'application/json' => :json,
          'text/html' => :html,
          'text/plain' => :text,
        }.freeze

        FORMAT_TO_CONTENT_TYPE = {
          'json' => 'application/json',
          'html' => 'text/html',
        }.freeze

        DEFAULT_CONTENT_TYPE = 'application/json'

        def content_type(http_accept_header)
          return DEFAULT_CONTENT_TYPE if http_accept_header.nil?

          accept_types = http_accept_header.split(',').map(&:strip)

          accepted = accept_types.map { |m| Utils::HTTP::MediaRange.new(m) }.sort!.reverse!

          accepted.each do |range|
            type_match = CONTENT_TYPE_TO_FORMAT.keys.find { |type| range === type }

            return type_match if type_match
          end

          DEFAULT_CONTENT_TYPE
        rescue Datadog::AppSec::Utils::HTTP::MediaRange::ParseError
          DEFAULT_CONTENT_TYPE
        end

        def content(content_type)
          content_format = CONTENT_TYPE_TO_FORMAT[content_type]

          using_default = Datadog.configuration.appsec.block.templates.using_default?(content_format)

          if using_default
            Datadog::AppSec::Assets.blocked(format: content_format)
          else
            Datadog.configuration.appsec.block.templates.send(content_format)
          end
        end
      end
    end
  end
end
