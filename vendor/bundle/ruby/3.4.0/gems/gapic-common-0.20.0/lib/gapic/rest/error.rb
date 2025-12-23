# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "json"
require "gapic/common/error"
require "google/protobuf/well_known_types"
# Not technically required but GRPC counterpart loads it and so should we for test parity
require "google/rpc/error_details_pb"

module Gapic
  module Rest
    # Gapic REST exception class
    class Error < ::Gapic::Common::Error
      # @return [Integer, nil] the http status code for the error
      attr_reader :status_code
      # @return [Object, nil] the text representation of status as parsed from the response body
      attr_reader :status
      # @return [Object, nil] the details as parsed from the response body
      attr_reader :details
      # The Cloud error wrapper expect to see a `status_details` property
      alias status_details details
      # @return [Object, nil] the headers of the REST error
      attr_reader :headers
      # The Cloud error wrapper expect to see a `header` property
      alias header headers

      ##
      # @param message [String, nil] error message
      # @param status_code [Integer, nil] HTTP status code of this error
      # @param status [String, nil] The text representation of status as parsed from the response body
      # @param details [Object, nil] Details data of this error
      # @param headers [Object, nil] Http headers data of this error
      #
      def initialize message, status_code, status: nil, details: nil, headers: nil
        super message
        @status_code = status_code
        @status = status
        @details = details
        @headers = headers
      end

      class << self
        ##
        # This creates a new error message wrapping the Faraday's one. Additionally
        # it tries to parse and set a detailed message and an error code from
        # from the Google Cloud's response body
        #
        # @param err [Faraday::Error] the Faraday error to wrap
        #
        # @return [ Gapic::Rest::Error]
        def wrap_faraday_error err
          message, status_code, status, details, headers = parse_faraday_error err
          Gapic::Rest::Error.new message, status_code, status: status, details: details, headers: headers
        end

        ##
        # @private
        # Tries to get the error information from Faraday error
        #
        # @param err [Faraday::Error] the Faraday error to extract information from
        # @return [Array(String, String, String, String, String)]
        def parse_faraday_error err
          message = err.message
          status_code = err.response_status
          status = nil
          details = nil
          headers = err.response_headers

          if err.response_body
            msg, code, status, details = try_parse_from_body err.response_body
            message = "An error has occurred when making a REST request: #{msg}" unless msg.nil?
            status_code = code unless code.nil?
          end

          [message, status_code, status, details, headers]
        end

        private

        ##
        # @private
        # Tries to get the error information from the JSON bodies
        #
        # @param body_str [String]
        # @return [Array(String, String, String, String)]
        def try_parse_from_body body_str
          body = JSON.parse body_str

          unless body.is_a?(::Hash) && body&.key?("error") && body["error"].is_a?(::Hash)
            return [nil, nil, nil, nil]
          end
          error = body["error"]

          message = error["message"] if error.key? "message"
          code = error["code"] if error.key? "code"
          status = error["status"] if error.key? "status"

          details = parse_details error["details"] if error.key? "details"

          [message, code, status, details]
        rescue JSON::ParserError
          [nil, nil, nil, nil]
        end

        ##
        # @private
        # Parses the details data, trying to extract the Protobuf.Any objects
        # from it, if it's an array of hashes. Otherwise returns it as is.
        #
        # @param details [Object, nil] the details object
        #
        # @return [Object, nil]
        def parse_details details
          # For rest errors details will contain json representations of `Protobuf.Any`
          # decoded into hashes. If it's not an array, of its elements are not hashes,
          # it's some other case
          return details unless details.is_a? ::Array

          details.map do |detail_instance|
            next detail_instance unless detail_instance.is_a? ::Hash
            # Next, parse detail_instance into a Proto message.
            # There are three possible issues for the JSON->Any->message parsing
            # - json decoding fails
            # - the json belongs to a proto message type we don't know about
            # - any unpacking fails
            # If we hit any of these three issues we'll just return the original hash
            begin
              any = ::Google::Protobuf::Any.decode_json detail_instance.to_json
              klass = ::Google::Protobuf::DescriptorPool.generated_pool.lookup(any.type_name)&.msgclass
              next detail_instance if klass.nil?
              unpack = any.unpack klass
              next detail_instance if unpack.nil?
              unpack
            rescue ::Google::Protobuf::ParseError
              detail_instance
            end
          end.compact
        end
      end
    end

    ##
    # An error class that represents DeadlineExceeded error for Rest
    # with an optional retry root cause.
    #
    # If the deadline for making a call was exceeded during the rest calls,
    # this exception is thrown wrapping Faraday::TimeoutError.
    #
    # If there were other exceptions retried before that, the last one will be
    # saved as a "root_cause".
    #
    # @!attribute [r] root_cause
    #   @return [Object, nil] The exception that was being retried
    #     when the Faraday::TimeoutError error occured.
    #
    class DeadlineExceededError < Error
      attr_reader :root_cause

      ##
      # @private
      # @param message [String, nil] error message
      # @param status_code [Integer, nil] HTTP status code of this error
      # @param status [String, nil] The text representation of status as parsed from the response body
      # @param details [Object, nil] Details data of this error
      # @param headers [Object, nil] Http headers data of this error
      # @param root_cause [Object, nil] The exception that was being retried
      #   when the Faraday::TimeoutError occured.
      #
      def initialize message, status_code, status: nil, details: nil, headers: nil, root_cause: nil
        super message, status_code, status: status, details: details, headers: headers
        @root_cause = root_cause
      end

      class << self
        ##
        # @private
        # This creates a new error message wrapping the Faraday's one. Additionally
        # it tries to parse and set a detailed message and an error code from
        # from the Google Cloud's response body
        #
        # @param err [Faraday::TimeoutError] the Faraday error to wrap
        #
        # @param root_cause [Object, nil] The exception that was being retried
        #   when the Faraday::TimeoutError occured.
        #
        # @return [ Gapic::Rest::DeadlineExceededError]
        def wrap_faraday_error err, root_cause: nil
          message, status_code, status, details, headers = parse_faraday_error err
          Gapic::Rest::DeadlineExceededError.new message,
                                                 status_code,
                                                 status: status,
                                                 details: details,
                                                 headers: headers,
                                                 root_cause: root_cause
        end
      end
    end
  end
end
