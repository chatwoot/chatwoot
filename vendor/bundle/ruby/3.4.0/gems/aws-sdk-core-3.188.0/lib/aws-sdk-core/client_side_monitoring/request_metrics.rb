# frozen_string_literal: true

module Aws
  module ClientSideMonitoring
    # @api private
    class RequestMetrics
      attr_reader :api_call, :api_call_attempts

      FIELD_MAX_LENGTH = {
        "ClientId" => 255,
        "UserAgent" => 256,
        "SdkException" => 128,
        "SdkExceptionMessage" => 512,
        "AwsException" => 128,
        "AwsExceptionMessage" => 512,
        "FinalAwsException" => 128,
        "FinalAwsExceptionMessage" => 512,
        "FinalSdkException" => 128,
        "FinalSdkExceptionMessage" => 512,
      }

      def initialize(opts = {})
        @service = opts[:service]
        @api = opts[:operation]
        @client_id = opts[:client_id]
        @timestamp = opts[:timestamp] # In epoch milliseconds
        @region = opts[:region]
        @version = 1
        @api_call = ApiCall.new(@service, @api, @client_id, @version, @timestamp, @region)
        @api_call_attempts = []
      end

      def build_call_attempt(opts = {})
        timestamp = opts[:timestamp]
        fqdn = opts[:fqdn]
        region = opts[:region]
        user_agent = opts[:user_agent]
        access_key = opts[:access_key]
        session_token = opts[:session_token]
        ApiCallAttempt.new(
          @service,
          @api,
          @client_id,
          @version,
          timestamp,
          fqdn,
          region,
          user_agent,
          access_key,
          session_token
        )
      end

      def add_call_attempt(attempt)
        @api_call_attempts << attempt
      end

      class ApiCall
        attr_reader :service, :api, :client_id, :timestamp, :version,
          :attempt_count, :latency, :region, :max_retries_exceeded,
          :final_http_status_code, :user_agent, :final_aws_exception,
          :final_aws_exception_message, :final_sdk_exception,
          :final_sdk_exception_message

        def initialize(service, api, client_id, version, timestamp, region)
          @service = service
          @api = api
          @client_id = client_id
          @version = version
          @timestamp = timestamp
          @region = region
        end

        def complete(opts = {})
          @latency = opts[:latency]
          @attempt_count = opts[:attempt_count]
          @user_agent = opts[:user_agent]
          if opts[:final_error_retryable]
            @max_retries_exceeded = 1
          else
            @max_retries_exceeded = 0
          end
          @final_http_status_code = opts[:final_http_status_code]
          @final_aws_exception = opts[:final_aws_exception]
          @final_aws_exception_message = opts[:final_aws_exception_message]
          @final_sdk_exception = opts[:final_sdk_exception]
          @final_sdk_exception_message = opts[:final_sdk_exception_message]
          @region = opts[:region] if opts[:region] # in case region changes
        end

        def to_json(*a)
          document = {
            "Type" => "ApiCall",
            "Service" => @service,
            "Api" => @api,
            "ClientId" => @client_id,
            "Timestamp" => @timestamp,
            "Version" => @version,
            "AttemptCount" => @attempt_count,
            "Latency" => @latency,
            "Region" => @region,
            "MaxRetriesExceeded" => @max_retries_exceeded,
            "UserAgent" => @user_agent,
            "FinalHttpStatusCode" => @final_http_status_code,
          }
          document["FinalSdkException"] = @final_sdk_exception if @final_sdk_exception
          document["FinalSdkExceptionMessage"] = @final_sdk_exception_message if @final_sdk_exception_message
          document["FinalAwsException"] = @final_aws_exception if @final_aws_exception
          document["FinalAwsExceptionMessage"] = @final_aws_exception_message if @final_aws_exception_message
          document = _truncate(document)
          document.to_json
        end

        private
        def _truncate(document)
          document.each do |key, value|
            limit = FIELD_MAX_LENGTH[key]
            if limit && value.to_s.length > limit
              document[key] = value.to_s.slice(0...limit)
            end
          end
          document
        end
      end

      class ApiCallAttempt
        attr_reader :service, :api, :client_id, :version, :timestamp,
          :user_agent, :access_key, :session_token
        attr_accessor :region, :fqdn, :request_latency, :http_status_code,
          :aws_exception_msg, :x_amz_request_id, :x_amz_id_2,
          :x_amzn_request_id, :sdk_exception, :aws_exception, :sdk_exception_msg

        def initialize(
          service,
          api,
          client_id,
          version,
          timestamp,
          fqdn,
          region,
          user_agent,
          access_key,
          session_token
        )
          @service = service
          @api = api
          @client_id = client_id
          @version = version
          @timestamp = timestamp
          @fqdn = fqdn
          @region = region
          @user_agent = user_agent
          @access_key = access_key
          @session_token = session_token
        end

        def to_json(*a)
          json = {
            "Type" => "ApiCallAttempt",
            "Service" => @service,
            "Api" => @api,
            "ClientId" => @client_id,
            "Timestamp" => @timestamp,
            "Version" => @version,
            "Fqdn" => @fqdn,
            "Region" => @region,
            "UserAgent" => @user_agent,
            "AccessKey" => @access_key
          }
          # Optional Fields
          json["SessionToken"] = @session_token if @session_token
          json["HttpStatusCode"] = @http_status_code if @http_status_code
          json["AwsException"] = @aws_exception if @aws_exception
          json["AwsExceptionMessage"] = @aws_exception_msg if @aws_exception_msg
          json["XAmznRequestId"] = @x_amzn_request_id if @x_amzn_request_id
          json["XAmzRequestId"] = @x_amz_request_id if @x_amz_request_id
          json["XAmzId2"] = @x_amz_id_2 if @x_amz_id_2
          json["AttemptLatency"] = @request_latency if @request_latency
          json["SdkException"] = @sdk_exception if @sdk_exception
          json["SdkExceptionMessage"] = @sdk_exception_msg if @sdk_exception_msg
          json = _truncate(json)
          json.to_json
        end

        private
        def _truncate(document)
          document.each do |key, value|
            limit = FIELD_MAX_LENGTH[key]
            if limit && value.to_s.length > limit
              document[key] = value.to_s.slice(0...limit)
            end
          end
          document
        end
      end

    end
  end
end
