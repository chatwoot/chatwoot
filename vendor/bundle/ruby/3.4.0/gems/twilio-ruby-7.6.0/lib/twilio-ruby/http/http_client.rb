# frozen_string_literal: true

require 'faraday'
require 'faraday/middleware'

module Twilio
  module HTTP
    class Client
      attr_accessor :adapter
      attr_reader :timeout, :last_response, :last_request, :connection

      def initialize(proxy_prot = nil, proxy_addr = nil, proxy_port = nil, proxy_user = nil, proxy_pass = nil,
                     timeout: nil)
        @proxy_prot = proxy_prot
        @proxy_path = "#{proxy_addr}:#{proxy_port}" if proxy_addr && proxy_port
        @proxy_auth = "#{proxy_user}:#{proxy_pass}@" if proxy_pass && proxy_user
        @timeout = timeout
        @adapter = Faraday.default_adapter
        @configure_connection_blocks = []
      end

      def configure_connection(&block)
        raise ArgumentError, "#{__method__} must be given a block!" unless block_given?

        @configure_connection_blocks << block
        nil
      end

      def _request(request) # rubocop:disable Metrics/MethodLength
        middle_ware = case request.headers['Content-Type']
                      when 'application/json'
                        :json
                      when 'application/x-www-form-urlencoded'
                        :url_encoded
                      else
                        :url_encoded
                      end
        @connection = Faraday.new(url: request.host + ':' + request.port.to_s, ssl: { verify: true }) do |f|
          f.options.params_encoder = Faraday::FlatParamsEncoder
          f.request(middle_ware)
          f.headers = request.headers
          if Faraday::VERSION.start_with?('2.')
            f.request(:authorization, :basic, request.auth[0], request.auth[1])
          else
            f.request(:basic_auth, request.auth[0], request.auth[1])
          end
          f.proxy = "#{@proxy_prot}://#{@proxy_auth}#{@proxy_path}" if @proxy_prot && @proxy_path
          f.options.open_timeout = request.timeout || @timeout
          f.options.timeout = request.timeout || @timeout
          f.params = request.params.nil? ? {} : request.params

          @configure_connection_blocks.each { |block| block.call(f) }
          f.adapter @adapter
        end

        @last_request = request
        @last_response = nil

        response = send(request)
        if (500..599).include?(response.status)
          object = { message: "Server error (#{response.status})", code: response.status }.to_json
        elsif response.body && !response.body.empty?
          object = response.body
        elsif response.status == 400
          object = { message: 'Bad request', code: 400 }.to_json
        end

        twilio_response = Twilio::Response.new(response.status, object, headers: response.headers)
        @last_response = twilio_response

        twilio_response
      end

      def send(request)
        @connection.send(request.method.downcase.to_sym,
                         request.url,
                         request.data)
      rescue Faraday::Error => e
        raise Twilio::REST::TwilioError, e
      end

      def request(host, port, method, url, params = {}, data = {}, headers = {}, auth = nil, timeout = nil)
        headers['Authorization'] = auth if jwt_token?(auth)
        request = Twilio::Request.new(host, port, method, url, params, data, headers, auth, timeout)
        _request(request)
      end

      def jwt_token?(auth)
        return false unless auth.is_a?(String)

        parts = auth.split('.')
        parts.length == 3
      end
    end
  end
end
