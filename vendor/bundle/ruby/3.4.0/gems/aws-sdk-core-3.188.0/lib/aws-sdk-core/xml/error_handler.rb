# frozen_string_literal: true

require 'cgi'

module Aws
  module Xml
    class ErrorHandler < Seahorse::Client::Handler

      def call(context)
        @handler.call(context).on(300..599) do |response|
          response.error = error(context) unless response.error
          response.data = nil
        end
      end

      private

      def error(context)
        body = context.http_response.body_contents
        if body.empty?
          code = http_status_error_code(context)
          message = ''
          data = EmptyStructure.new
        else
          code, message, data = extract_error(body, context)
        end
        context[:request_id] = request_id(body)
        errors_module = context.client.class.errors_module
        error_class = errors_module.error_class(code).new(context, message, data)
        error_class
      end

      def extract_error(body, context)
        code = error_code(body, context)
        [
          code,
          error_message(body),
          error_data(context, code)
        ]
      end

      def error_data(context, code)
        data = EmptyStructure.new
        if error_rules = context.operation.errors
          error_rules.each do |rule|
            # for modeled shape with error trait
            # match `code` in the error trait before
            # match modeled shape name
            error_shape_code = rule.shape['error']['code'] if rule.shape['error']
            match = (code == error_shape_code || code == rule.shape.name)
            if match && rule.shape.members.any?
              data = Parser.new(rule).parse(context.http_response.body_contents)
            end
          end
        end
        data
      rescue Xml::Parser::ParsingError
        EmptyStructure.new
      end

      def error_code(body, context)
        if matches = body.match(/<Code>(.+?)<\/Code>/)
          remove_prefix(unescape(matches[1]), context)
        else
          http_status_error_code(context)
        end
      end

      def http_status_error_code(context)
        status_code = context.http_response.status_code
        {
          302 => 'MovedTemporarily',
          304 => 'NotModified',
          400 => 'BadRequest',
          403 => 'Forbidden',
          404 => 'NotFound',
          412 => 'PreconditionFailed',
          413 => 'RequestEntityTooLarge',
        }[status_code] || "Http#{status_code}Error"
      end

      def remove_prefix(error_code, context)
        if prefix = context.config.api.metadata['errorPrefix']
          error_code.sub(/^#{prefix}/, '')
        else
          error_code
        end
      end

      def error_message(body)
        if matches = body.match(/<Message>(.+?)<\/Message>/m)
          unescape(matches[1])
        else
          ''
        end
      end

      def request_id(body)
        if matches = body.match(/<RequestId>(.+?)<\/RequestId>/m)
          matches[1]
        end
      end

      def unescape(str)
        CGI.unescapeHTML(str)
      end

    end
  end
end
