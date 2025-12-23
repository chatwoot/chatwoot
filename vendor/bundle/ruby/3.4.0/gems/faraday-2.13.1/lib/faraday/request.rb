# frozen_string_literal: true

module Faraday
  # Used to setup URLs, params, headers, and the request body in a sane manner.
  #
  # @example
  #   @connection.post do |req|
  #     req.url 'http://localhost', 'a' => '1' # 'http://localhost?a=1'
  #     req.headers['b'] = '2' # Header
  #     req.params['c']  = '3' # GET Param
  #     req['b']         = '2' # also Header
  #     req.body = 'abc'
  #   end
  #
  # @!attribute http_method
  #   @return [Symbol] the HTTP method of the Request
  # @!attribute path
  #   @return [URI, String] the path
  # @!attribute params
  #   @return [Hash] query parameters
  # @!attribute headers
  #   @return [Faraday::Utils::Headers] headers
  # @!attribute body
  #   @return [String] body
  # @!attribute options
  #   @return [RequestOptions] options
  Request = Struct.new(:http_method, :path, :params, :headers, :body, :options) do
    extend MiddlewareRegistry

    alias_method :member_get, :[]
    private :member_get
    alias_method :member_set, :[]=
    private :member_set

    # @param request_method [String]
    # @yield [request] for block customization, if block given
    # @yieldparam request [Request]
    # @return [Request]
    def self.create(request_method)
      new(request_method).tap do |request|
        yield(request) if block_given?
      end
    end

    remove_method :params=
    # Replace params, preserving the existing hash type.
    #
    # @param hash [Hash] new params
    def params=(hash)
      if params
        params.replace hash
      else
        member_set(:params, hash)
      end
    end

    remove_method :headers=
    # Replace request headers, preserving the existing hash type.
    #
    # @param hash [Hash] new headers
    def headers=(hash)
      if headers
        headers.replace hash
      else
        member_set(:headers, hash)
      end
    end

    # Update path and params.
    #
    # @param path [URI, String]
    # @param params [Hash, nil]
    # @return [void]
    def url(path, params = nil)
      if path.respond_to? :query
        if (query = path.query)
          path = path.dup
          path.query = nil
        end
      else
        anchor_index = path.index('#')
        path = path.slice(0, anchor_index) unless anchor_index.nil?
        path, query = path.split('?', 2)
      end
      self.path = path
      self.params.merge_query query, options.params_encoder
      self.params.update(params) if params
    end

    # @param key [Object] key to look up in headers
    # @return [Object] value of the given header name
    def [](key)
      headers[key]
    end

    # @param key [Object] key of header to write
    # @param value [Object] value of header
    def []=(key, value)
      headers[key] = value
    end

    # Marshal serialization support.
    #
    # @return [Hash] the hash ready to be serialized in Marshal.
    def marshal_dump
      {
        http_method: http_method,
        body: body,
        headers: headers,
        path: path,
        params: params,
        options: options
      }
    end

    # Marshal serialization support.
    # Restores the instance variables according to the +serialised+.
    # @param serialised [Hash] the serialised object.
    def marshal_load(serialised)
      self.http_method = serialised[:http_method]
      self.body = serialised[:body]
      self.headers = serialised[:headers]
      self.path = serialised[:path]
      self.params = serialised[:params]
      self.options = serialised[:options]
    end

    # @return [Env] the Env for this Request
    def to_env(connection)
      Env.new(http_method, body, connection.build_exclusive_url(path, params),
              options, headers, connection.ssl, connection.parallel_manager)
    end
  end
end

require 'faraday/request/authorization'
require 'faraday/request/instrumentation'
require 'faraday/request/json'
require 'faraday/request/url_encoded'
