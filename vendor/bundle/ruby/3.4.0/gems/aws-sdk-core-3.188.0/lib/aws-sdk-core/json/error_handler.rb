# frozen_string_literal: true

module Aws
  module Json
    class ErrorHandler < Xml::ErrorHandler

      # @param [Seahorse::Client::RequestContext] context
      # @return [Seahorse::Client::Response]
      def call(context)
        @handler.call(context).on(300..599) do |response|
          response.error = error(context)
          response.data = nil
        end
      end

      private

      def extract_error(body, context)
        json = Json.load(body)
        code = error_code(json, context)
        message = error_message(code, json)
        data = parse_error_data(context, code)
        [code, message, data]
      rescue Json::ParseError
        [http_status_error_code(context), '', EmptyStructure.new]
      end

      def error_code(json, context)
        code =
          if aws_query_error?(context)
            error = context.http_response.headers['x-amzn-query-error'].split(';')[0]
            remove_prefix(error, context)
          else
            json['__type']
          end
        code ||= json['code']
        code ||= context.http_response.headers['x-amzn-errortype']
        if code
          code.split('#').last
        else
          http_status_error_code(context)
        end
      end

      def aws_query_error?(context)
        context.config.api.metadata['awsQueryCompatible'] &&
          context.http_response.headers['x-amzn-query-error']
      end

      def remove_prefix(error_code, context)
        if prefix = context.config.api.metadata['errorPrefix']
          error_code.sub(/^#{prefix}/, '')
        else
          error_code
        end
      end

      def error_message(code, json)
        if code == 'RequestEntityTooLarge'
          'Request body must be less than 1 MB'
        else
          json['message'] || json['Message'] || ''
        end
      end

      def parse_error_data(context, code)
        data = EmptyStructure.new
        if error_rules = context.operation.errors
          error_rules.each do |rule|
            # match modeled shape name with the type(code) only
            # some type(code) might contains invalid characters
            # such as ':' (efs) etc
            match = rule.shape.name == code.gsub(/[^^a-zA-Z0-9]/, '')
            if match && rule.shape.members.any?
              data = Parser.new(rule).parse(context.http_response.body_contents)
            end
          end
        end
        data
      end

    end
  end
end
