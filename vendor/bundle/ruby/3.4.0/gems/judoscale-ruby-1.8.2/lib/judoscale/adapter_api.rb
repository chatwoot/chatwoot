# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "judoscale/logger"

module Judoscale
  class AdapterApi
    include Logger

    SUCCESS = "success"
    TRANSIENT_ERRORS = [
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Net::OpenTimeout,
      Net::ReadTimeout,
      OpenSSL::SSL::SSLError
    ]

    def initialize(config)
      @config = config
    end

    def report_metrics(report_json)
      post_json "/v3/reports", report_json
    end

    private

    def post_json(path, data)
      headers = {"Content-Type" => "application/json"}
      post_raw path: path, body: JSON.dump(data), headers: headers
    end

    def post_raw(options)
      attempts ||= 1
      uri = URI.parse("#{@config.api_base_url}#{options.fetch(:path)}")
      ssl = uri.scheme == "https"

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: ssl) do |http|
        request = Net::HTTP::Post.new(uri.request_uri, options[:headers] || {})
        request.body = options.fetch(:body)

        logger.debug "Posting #{request.body.size} bytes to #{uri}"
        http.request(request)
      end

      case response.code.to_i
      when 200...300 then SuccessResponse.new(response.body)
      else FailureResponse.new([response.code, response.message].join(" - "))
      end
    rescue *TRANSIENT_ERRORS => ex
      if attempts < 3
        # TCP timeouts happen sometimes, but they can usually be successfully retried in a moment
        sleep 0.01
        attempts += 1
        retry
      else
        FailureResponse.new("Could not connect to #{uri.host}: #{ex.inspect}")
      end
    end

    class SuccessResponse < Struct.new(:body)
      def data
        JSON.parse(body)
      rescue TypeError
        {}
      end
    end

    class FailureResponse < Struct.new(:failure_message)
    end
  end
end
