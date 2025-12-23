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

module Gapic
  module GenericLRO
    ##
    # A base class for the wrappers over the long-running operations.
    #
    # @attribute [r] operation
    #   @return [Object] The wrapped operation object.
    #
    class BaseOperation
      attr_reader :operation

      ##
      # @private
      # @param operation [Object] The operation object to be wrapped
      def initialize operation
        @operation = operation
      end

      protected

      attr_writer :operation
    end
  end
end
