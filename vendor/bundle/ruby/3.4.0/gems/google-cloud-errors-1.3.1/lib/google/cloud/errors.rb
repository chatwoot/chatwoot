# Copyright 2020 Google LLC
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


require "English"

module Google
  module Cloud
    ##
    # Base google-cloud exception class.
    class Error < StandardError
      ##
      # Construct a new Google::Cloud::Error object, optionally passing in a
      # message.
      #
      # @param msg [String, nil] an error message
      def initialize msg = nil
        super
      end

      ##
      # Returns the value of `status_code` from the underlying cause error
      # object, if both are present. Otherwise returns `nil`.
      #
      # This is typically present on errors originating from calls to an API
      # over HTTP/REST.
      #
      # @return [Object, nil]
      def status_code
        return nil unless cause.respond_to? :status_code
        cause.status_code
      end

      ##
      # Returns the value of `body` from the underlying cause error
      # object, if both are present. Otherwise returns `nil`.
      #
      # This is typically present on errors originating from calls to an API
      # over HTTP/REST.
      #
      # @return [Object, nil]
      def body
        return nil unless cause.respond_to? :body
        cause.body
      end

      ##
      # Returns the value of `header` from the underlying cause error
      # object, if both are present. Otherwise returns `nil`.
      #
      # This is typically present on errors originating from calls to an API
      # over HTTP/REST.
      #
      # @return [Object, nil]
      def header
        return nil unless cause.respond_to? :header
        cause.header
      end

      ##
      # Returns the value of `code` from the underlying cause error
      # object, if both are present. Otherwise returns `nil`.
      #
      # This is typically present on errors originating from calls to an API
      # over gRPC.
      #
      # @return [Object, nil]
      def code
        return nil unless cause.respond_to? :code
        cause.code
      end

      ##
      # Returns the value of `details` from the underlying cause error
      # object, if both are present. Otherwise returns `nil`.
      #
      # This is typically present on errors originating from calls to an API
      # over gRPC.
      #
      # @return [Object, nil]
      def details
        return nil unless cause.respond_to? :details
        cause.details
      end

      ##
      # Returns the value of `metadata` from the underlying cause error
      # object, if both are present. Otherwise returns `nil`.
      #
      # This is typically present on errors originating from calls to an API
      # over gRPC.
      #
      # @return [Object, nil]
      def metadata
        return nil unless cause.respond_to? :metadata
        cause.metadata
      end

      ##
      # Returns the value of `status_details` from the underlying cause error
      # object, if both are present. Otherwise returns `nil`.
      #
      # This is typically present on errors originating from calls to an API
      # over gRPC.
      #
      # @return [Object, nil]
      def status_details
        return nil unless cause.respond_to? :status_details
        cause.status_details
      end

      ##
      # Returns the `::Google::Rpc::ErrorInfo` object present in the `status_details`
      # or `details` array, given that the following is true:
      #   * either `status_details` or `details` exists and is an array
      #   * there is exactly one `::Google::Rpc::ErrorInfo` object in that array.
      # Looks in `status_details` first, then in `details`.
      #
      # @return [::Google::Rpc::ErrorInfo, nil]
      def error_info
        @error_info ||= begin
          check_property = lambda do |prop|
            if prop.is_a? Array
              error_infos = prop.find_all { |status| status.is_a?(::Google::Rpc::ErrorInfo) }
              if error_infos.length == 1
                error_infos[0]
              end
            end
          end

          check_property.call(status_details) || check_property.call(details)
        end
      end

      ##
      # Returns the value of `domain` from the `::Google::Rpc::ErrorInfo`
      # object, if it exists in the `status_details` array.
      #
      # This is typically present on errors originating from calls to an API
      # over gRPC.
      #
      # @return [Object, nil]
      def domain
        return nil unless error_info.respond_to? :domain
        error_info.domain
      end

      ##
      # Returns the value of `reason` from the `::Google::Rpc::ErrorInfo`
      # object, if it exists in the `status_details` array.
      #
      # This is typically present on errors originating from calls to an API
      # over gRPC.
      #
      # @return [Object, nil]
      def reason
        return nil unless error_info.respond_to? :reason
        error_info.reason
      end

      ##
      # Returns the value of `metadata` from the `::Google::Rpc::ErrorInfo`
      # object, if it exists in the `status_details` array.
      #
      # This is typically present on errors originating from calls to an API
      # over gRPC.
      #
      # @return [Hash, nil]
      def error_metadata
        return nil unless error_info.respond_to? :metadata
        error_info.metadata.to_h
      end

      # @private Create a new error object from a client error
      def self.from_error error
        klass = if error.respond_to? :code
                  grpc_error_class_for error.code
                elsif error.respond_to? :status_code
                  gapi_error_class_for error.status_code
                else
                  self
                end
        klass.new error.message
      end

      # @private Identify the subclass for a gRPC error
      def self.grpc_error_class_for grpc_error_code
        # The gRPC status code 0 is for a successful response.
        # So there is no error subclass for a 0 status code, use current class.
        [
          self, CanceledError, UnknownError, InvalidArgumentError,
          DeadlineExceededError, NotFoundError, AlreadyExistsError,
          PermissionDeniedError, ResourceExhaustedError,
          FailedPreconditionError, AbortedError, OutOfRangeError,
          UnimplementedError, InternalError, UnavailableError, DataLossError,
          UnauthenticatedError
        ][grpc_error_code] || self
      end

      # @private Identify the subclass for a Google API Client error
      def self.gapi_error_class_for http_status_code
        # The http status codes mapped to their error classes.
        {
          400 => InvalidArgumentError, # FailedPreconditionError/OutOfRangeError
          401 => UnauthenticatedError,
          403 => PermissionDeniedError,
          404 => NotFoundError,
          409 => AlreadyExistsError, # AbortedError
          412 => FailedPreconditionError,
          429 => ResourceExhaustedError,
          499 => CanceledError,
          500 => InternalError, # UnknownError/DataLossError
          501 => UnimplementedError,
          503 => UnavailableError,
          504 => DeadlineExceededError
        }[http_status_code] || self
      end
    end

    ##
    # Canceled indicates the operation was cancelled (typically by the caller).
    class CanceledError < Error
      ##
      # gRPC error code for CANCELLED
      #
      # @return [Integer]
      def code
        1
      end
    end

    ##
    # Unknown error.  An example of where this error may be returned is
    # if a Status value received from another address space belongs to
    # an error-space that is not known in this address space.  Also
    # errors raised by APIs that do not return enough error information
    # may be converted to this error.
    class UnknownError < Error
      ##
      # gRPC error code for UNKNOWN
      #
      # @return [Integer]
      def code
        2
      end
    end

    ##
    # InvalidArgument indicates client specified an invalid argument.
    # Note that this differs from FailedPrecondition. It indicates arguments
    # that are problematic regardless of the state of the system
    # (e.g., a malformed file name).
    class InvalidArgumentError < Error
      ##
      # gRPC error code for INVALID_ARGUMENT
      #
      # @return [Integer]
      def code
        3
      end
    end

    ##
    # DeadlineExceeded means operation expired before completion.
    # For operations that change the state of the system, this error may be
    # returned even if the operation has completed successfully. For
    # example, a successful response from a server could have been delayed
    # long enough for the deadline to expire.
    class DeadlineExceededError < Error
      ##
      # gRPC error code for DEADLINE_EXCEEDED
      #
      # @return [Integer]
      def code
        4
      end
    end

    ##
    # NotFound means some requested entity (e.g., file or directory) was
    # not found.
    class NotFoundError < Error
      ##
      # gRPC error code for NOT_FOUND
      #
      # @return [Integer]
      def code
        5
      end
    end

    ##
    # AlreadyExists means an attempt to create an entity failed because one
    # already exists.
    class AlreadyExistsError < Error
      ##
      # gRPC error code for ALREADY_EXISTS
      #
      # @return [Integer]
      def code
        6
      end
    end

    ##
    # PermissionDenied indicates the caller does not have permission to
    # execute the specified operation. It must not be used for rejections
    # caused by exhausting some resource (use ResourceExhausted
    # instead for those errors).  It must not be
    # used if the caller cannot be identified (use Unauthenticated
    # instead for those errors).
    class PermissionDeniedError < Error
      ##
      # gRPC error code for PERMISSION_DENIED
      #
      # @return [Integer]
      def code
        7
      end
    end

    ##
    # ResourceExhausted indicates some resource has been exhausted, perhaps
    # a per-user quota, or perhaps the entire file system is out of space.
    class ResourceExhaustedError < Error
      ##
      # gRPC error code for RESOURCE_EXHAUSTED
      #
      # @return [Integer]
      def code
        8
      end
    end

    ##
    # FailedPrecondition indicates operation was rejected because the
    # system is not in a state required for the operation's execution.
    # For example, directory to be deleted may be non-empty, an rmdir
    # operation is applied to a non-directory, etc.
    #
    # A litmus test that may help a service implementor in deciding
    # between FailedPrecondition, Aborted, and Unavailable:
    #  (a) Use Unavailable if the client can retry just the failing call.
    #  (b) Use Aborted if the client should retry at a higher-level
    #      (e.g., restarting a read-modify-write sequence).
    #  (c) Use FailedPrecondition if the client should not retry until
    #      the system state has been explicitly fixed.  E.g., if an "rmdir"
    #      fails because the directory is non-empty, FailedPrecondition
    #      should be returned since the client should not retry unless
    #      they have first fixed up the directory by deleting files from it.
    #  (d) Use FailedPrecondition if the client performs conditional
    #      REST Get/Update/Delete on a resource and the resource on the
    #      server does not match the condition. E.g., conflicting
    #      read-modify-write on the same resource.
    class FailedPreconditionError < Error
      ##
      # gRPC error code for FAILED_PRECONDITION
      #
      # @return [Integer]
      def code
        9
      end
    end

    ##
    # Aborted indicates the operation was aborted, typically due to a
    # concurrency issue like sequencer check failures, transaction aborts,
    # etc.
    #
    # See litmus test above for deciding between FailedPrecondition,
    # Aborted, and Unavailable.
    class AbortedError < Error
      ##
      # gRPC error code for ABORTED
      #
      # @return [Integer]
      def code
        10
      end
    end

    ##
    # OutOfRange means operation was attempted past the valid range.
    # E.g., seeking or reading past end of file.
    #
    # Unlike InvalidArgument, this error indicates a problem that may
    # be fixed if the system state changes. For example, a 32-bit file
    # system will generate InvalidArgument if asked to read at an
    # offset that is not in the range [0,2^32-1], but it will generate
    # OutOfRange if asked to read from an offset past the current
    # file size.
    #
    # There is a fair bit of overlap between FailedPrecondition and
    # OutOfRange.  We recommend using OutOfRange (the more specific
    # error) when it applies so that callers who are iterating through
    # a space can easily look for an OutOfRange error to detect when
    # they are done.
    class OutOfRangeError < Error
      ##
      # gRPC error code for OUT_OF_RANGE
      #
      # @return [Integer]
      def code
        11
      end
    end

    ##
    # Unimplemented indicates operation is not implemented or not
    # supported/enabled in this service.
    class UnimplementedError < Error
      ##
      # gRPC error code for UNIMPLEMENTED
      #
      # @return [Integer]
      def code
        12
      end
    end

    ##
    # Internal errors.  Means some invariants expected by underlying
    # system has been broken.  If you see one of these errors,
    # something is very broken.
    class InternalError < Error
      ##
      # gRPC error code for INTERNAL
      #
      # @return [Integer]
      def code
        13
      end
    end

    ##
    # Unavailable indicates the service is currently unavailable.
    # This is a most likely a transient condition and may be corrected
    # by retrying with a backoff.
    #
    # See litmus test above for deciding between FailedPrecondition,
    # Aborted, and Unavailable.
    class UnavailableError < Error
      ##
      # gRPC error code for UNAVAILABLE
      #
      # @return [Integer]
      def code
        14
      end
    end

    ##
    # DataLoss indicates unrecoverable data loss or corruption.
    class DataLossError < Error
      ##
      # gRPC error code for DATA_LOSS
      #
      # @return [Integer]
      def code
        15
      end
    end

    ##
    # Unauthenticated indicates the request does not have valid
    # authentication credentials for the operation.
    class UnauthenticatedError < Error
      ##
      # gRPC error code for UNAUTHENTICATED
      #
      # @return [Integer]
      def code
        16
      end
    end
  end
end
