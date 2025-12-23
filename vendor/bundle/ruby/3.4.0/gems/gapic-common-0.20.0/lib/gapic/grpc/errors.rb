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

require "googleauth"
require "gapic/common/error"

module Gapic
  module GRPC
    ##
    # An error class to represent the Authorization Error.
    # The GRPC layer wraps auth plugin errors in ::GRPC::Unavailable.
    # This class rewraps those GRPC layer errors, presenting a correct status code.
    #
    class AuthorizationError < ::GRPC::Unauthenticated
    end

    ##
    # An error class that represents Deadline Exceeded error with an optional
    # retry root cause.
    #
    # The GRPC layer throws ::GRPC::DeadlineExceeded without any context.
    # If the deadline was exceeded while retrying another exception (e.g.
    # ::GRPC::Unavailable), that exception could be useful for understanding
    # the readon for the timeout.
    #
    # This exception rewraps ::GRPC::DeadlineExceeded, adding an exception
    # that was being retried until the deadline was exceeded (if any) as a
    # `root_cause` attribute.
    #
    # @!attribute [r] root_cause
    #   @return [Object, nil] The exception that was being retried
    #     when the DeadlineExceeded error occured.
    #
    class DeadlineExceededError < ::GRPC::DeadlineExceeded
      attr_reader :root_cause

      ##
      # @param message [String] The error message.
      #
      # @param root_cause [Object, nil] The exception that was being retried
      #   when the DeadlineExceeded error occured.
      #
      def initialize message, root_cause: nil
        super message
        @root_cause = root_cause
      end
    end
  end
end
