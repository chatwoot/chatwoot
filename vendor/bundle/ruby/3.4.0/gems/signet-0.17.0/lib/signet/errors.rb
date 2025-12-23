# Copyright (C) 2010 Google Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

require "addressable/uri"

module Signet
  ##
  # An error indicating that the client has aborted an operation that
  # would have been unsafe to perform.
  class UnsafeOperationError < StandardError
  end

  ##
  # An error indicating the client failed to parse a value.
  class ParseError < StandardError
  end

  ##
  # An error indicating that the server considers the Authorization header to
  # be malformed(missing/unsupported/invalid parameters), and the request
  # should be considered invalid.
  class MalformedAuthorizationError < StandardError
  end

  ##
  # An error indicating that the server failed at processing the request
  # due to a internal error
  class RemoteServerError < StandardError
  end

  ##
  # An error indicating that the server sent an unexpected http status
  class UnexpectedStatusError < StandardError
  end

  ##
  # An error indicating the remote server refused to authorize the client.
  class AuthorizationError < StandardError
    ##
    # Creates a new authentication error.
    #
    # @param [String] message
    #   A message describing the error.
    # @param [Hash] options
    #   The configuration parameters for the request.
    #   - <code>:request</code> -
    #     A Faraday::Request object.  Optional.
    #   - <code>:response</code> -
    #     A Faraday::Response object.  Optional.
    #   - <code>:code</code> -
    #     An error code.
    #   - <code>:description</code> -
    #     Human-readable text intended to be used to assist in resolving the
    #     error condition.
    #   - <code>:uri</code> -
    #     A URI identifying a human-readable web page with additional
    #     information about the error, indended for the resource owner.
    def initialize message, options = {}
      super message
      @options = options
      @request = options[:request]
      @response = options[:response]
      @code = options[:code]
      @description = options[:description]
      @uri = Addressable::URI.parse options[:uri]
    end

    ##
    # The HTTP request that triggered this authentication error.
    #
    # @return [Array] A tuple of method, uri, headers, and body.
    attr_reader :request

    ##
    # The HTTP response that triggered this authentication error.
    #
    # @return [Array] A tuple of status, headers, and body.
    attr_reader :response
  end
end
