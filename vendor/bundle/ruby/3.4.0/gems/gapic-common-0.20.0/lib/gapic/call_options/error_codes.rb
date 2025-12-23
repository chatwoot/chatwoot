# Copyright 2019 Google LLC
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

module Gapic
  class CallOptions
    ##
    # @private
    # The gRPC error codes and their HTTP mapping
    #
    module ErrorCodes
      # @private
      # See https://grpc.github.io/grpc/core/md_doc_statuscodes.html for a
      # list of error codes.
      error_code_mapping = [
        "OK",
        "CANCELLED",
        "UNKNOWN",
        "INVALID_ARGUMENT",
        "DEADLINE_EXCEEDED",
        "NOT_FOUND",
        "ALREADY_EXISTS",
        "PERMISSION_DENIED",
        "RESOURCE_EXHAUSTED",
        "FAILED_PRECONDITION",
        "ABORTED",
        "OUT_OF_RANGE",
        "UNIMPLEMENTED",
        "INTERNAL",
        "UNAVAILABLE",
        "DATA_LOSS",
        "UNAUTHENTICATED"
      ].freeze

      # @private
      ERROR_STRING_MAPPING = error_code_mapping.each_with_index.to_h.freeze

      # @private
      HTTP_GRPC_CODE_MAP = {
        400 => 3, # InvalidArgumentError
        401 => 16, # UnauthenticatedError
        403 => 7, # PermissionDeniedError
        404 => 5, # NotFoundError
        409 => 6, # AlreadyExistsError
        412 => 9, # FailedPreconditionError
        429 => 8, # ResourceExhaustedError
        499 => 1, # CanceledError
        500 => 13, # InternalError
        501 => 12, # UnimplementedError
        503 => 14, # UnavailableError
        504 => 4 # DeadlineExceededError
      }.freeze

      # @private
      # Converts http error codes into corresponding gRPC ones
      def self.grpc_error_for http_error_code
        return 2 unless http_error_code

        # The http status codes mapped to their error classes.
        HTTP_GRPC_CODE_MAP[http_error_code] || 2 # UnknownError
      end
    end
  end
end
