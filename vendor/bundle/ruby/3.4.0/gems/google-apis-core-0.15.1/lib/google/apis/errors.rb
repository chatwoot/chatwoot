# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Google
  module Apis
    # Base error, capable of wrapping another
    class Error < StandardError
      attr_reader :status_code
      attr_reader :header
      attr_reader :body

      def initialize(err, status_code: nil, header: nil, body: nil)
        @cause = nil

        if err.respond_to?(:backtrace)
          super(err.message)
          @cause = err
        else
          super(err.to_s)
        end
        @status_code = status_code
        @header = header.dup unless header.nil?
        @body = body
      end

      def backtrace
        if @cause
          @cause.backtrace
        else
          super
        end
      end

      def inspect
        extra = ""
        extra << " status_code: #{status_code.inspect}" unless status_code.nil?
        extra << " header: #{header.inspect}"           unless header.nil?
        extra << " body: #{body.inspect}"               unless body.nil?

        "#<#{self.class.name}: #{message}#{extra}>"
      end
    end

    # An error which is raised when there is an unexpected response or other
    # transport error that prevents an operation from succeeding.
    class TransmissionError < Error
    end

    # An exception that is raised if a redirect is required
    #
    class RedirectError < Error
    end

    # A 4xx class HTTP error occurred.
    class ClientError < Error
    end

    # A 408 HTTP error occurred.
    class RequestTimeOutError < ClientError
    end

    # A 429 HTTP error occurred.
    class RateLimitError < Error
    end

    # A 403 HTTP error occurred.
    class ProjectNotLinkedError < Error
    end

    # A 401 HTTP error occurred.
    class AuthorizationError < Error
    end

    # A 5xx class HTTP error occurred.
    class ServerError < Error
    end

    # Error class for problems in batch requests.
    class BatchError < Error
    end

    # Error class for universe domain issues
    class UniverseDomainError < Error
    end
  end
end
