# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'rack'
require 'new_relic/rack/agent_middleware'
require 'new_relic/agent/instrumentation/middleware_proxy'

module NewRelic
  module Rack
    # This middleware is used by the agent for the Real user monitoring (RUM)
    # feature, and will usually be automatically injected in the middleware chain.
    # If automatic injection is not working, you may manually use it in your
    # middleware chain instead.
    #
    # @api public
    #
    class BrowserMonitoring < AgentMiddleware
      # The maximum number of bytes of the response body that we will
      # examine in order to look for a RUM insertion point.
      SCAN_LIMIT = 50_000

      CONTENT_TYPE = 'Content-Type'.freeze
      CONTENT_DISPOSITION = 'Content-Disposition'.freeze
      CONTENT_LENGTH = 'Content-Length'.freeze
      ATTACHMENT = 'attachment'.freeze
      TEXT_HTML = 'text/html'.freeze

      BODY_START = '<body'.freeze
      HEAD_START = '<head'.freeze
      GT = '>'.freeze

      ALREADY_INSTRUMENTED_KEY = 'newrelic.browser_monitoring_already_instrumented'
      CHARSET_RE = /<\s*meta[^>]+charset\s*=[^>]*>/im.freeze
      X_UA_COMPATIBLE_RE = /<\s*meta[^>]+http-equiv\s*=\s*['"]x-ua-compatible['"][^>]*>/im.freeze

      def traced_call(env)
        result = @app.call(env)
        (status, headers, response) = result

        js_to_inject = NewRelic::Agent.browser_timing_header
        if (js_to_inject != NewRelic::EMPTY_STR) && should_instrument?(env, status, headers)
          response_string = autoinstrument_source(response, js_to_inject)
          if headers.key?(CONTENT_LENGTH)
            content_length = response_string ? response_string.bytesize : 0
            headers[CONTENT_LENGTH] = content_length.to_s
          end

          env[ALREADY_INSTRUMENTED_KEY] = true
          if response_string
            response = ::Rack::Response.new(response_string, status, headers)
            response.finish
          else
            result
          end
        else
          result
        end
      end

      def should_instrument?(env, status, headers)
        NewRelic::Agent.config[:'browser_monitoring.auto_instrument'] &&
          status == 200 &&
          !env[ALREADY_INSTRUMENTED_KEY] &&
          html?(headers) &&
          !attachment?(headers) &&
          !streaming?(env, headers)
      end

      private

      def autoinstrument_source(response, js_to_inject)
        source = gather_source(response)
        close_old_response(response)
        return unless source

        modify_source(source, js_to_inject)
      rescue => e
        NewRelic::Agent.logger.debug("Skipping RUM instrumentation on exception: #{e.class} - #{e.message}")
      end

      def modify_source(source, js_to_inject)
        # Only scan the first 50k (roughly) then give up.
        beginning_of_source = source[0..SCAN_LIMIT]
        meta_tag_positions = find_meta_tag_positions(beginning_of_source)
        if body_start = find_body_start(beginning_of_source)
          if insertion_index = find_insertion_index(meta_tag_positions, beginning_of_source, body_start)
            source = source_injection(source, insertion_index, js_to_inject)
          else
            NewRelic::Agent.logger.debug('Skipping RUM instrumentation. Could not properly determine location to ' \
                                         'inject script.')
          end
        else
          msg = "Skipping RUM instrumentation. Unable to find <body> tag in first #{SCAN_LIMIT} bytes of document."
          NewRelic::Agent.logger.log_once(:warn, :rum_insertion_failure, msg)
          NewRelic::Agent.logger.debug(msg)
        end
        source
      end

      def html?(headers)
        # needs else branch coverage
        headers[CONTENT_TYPE] && headers[CONTENT_TYPE].include?(TEXT_HTML) # rubocop:disable Style/SafeNavigation
      end

      def attachment?(headers)
        headers[CONTENT_DISPOSITION]&.include?(ATTACHMENT)
      end

      def streaming?(env, headers)
        # Chunked transfer encoding is a streaming data transfer mechanism available only in HTTP/1.1
        return true if headers && headers['Transfer-Encoding'] == 'chunked'

        defined?(ActionController::Live) &&
          env['action_controller.instance'].class.included_modules.include?(ActionController::Live)
      end

      def source_injection(source, insertion_index, js_to_inject)
        source[0...insertion_index] <<
          js_to_inject <<
          source[insertion_index..-1]
      end

      def find_insertion_index(tag_positions, source_beginning, body_start)
        if !tag_positions.empty?
          tag_positions.max
        else
          find_end_of_head_open(source_beginning) || body_start
        end
      end

      def find_meta_tag_positions(source_beginning)
        [
          find_x_ua_compatible_position(source_beginning),
          find_charset_position(source_beginning)
        ].compact
      end

      def gather_source(response)
        source = nil
        response.each { |fragment| source ? (source << fragment.to_s) : (source = fragment.to_s) }
        source
      end

      # Per "The Response > The Body" section of Rack spec, we should close
      # if our response is able. https://github.com/rack/rack/blob/main/SPEC.rdoc
      def close_old_response(response)
        response.close if response.respond_to?(:close)
      end

      def find_body_start(beginning_of_source)
        beginning_of_source.index(BODY_START)
      end

      def find_x_ua_compatible_position(beginning_of_source)
        match = X_UA_COMPATIBLE_RE.match(beginning_of_source)
        match&.end(0)
      end

      def find_charset_position(beginning_of_source)
        match = CHARSET_RE.match(beginning_of_source)
        match&.end(0)
      end

      def find_end_of_head_open(beginning_of_source)
        head_open = beginning_of_source.index(HEAD_START)
        beginning_of_source.index(GT, head_open) + 1 if head_open
      end
    end
  end
end
