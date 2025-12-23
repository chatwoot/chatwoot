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

require "gapic/call_options/error_codes"
require "gapic/call_options/retry_policy"

module Gapic
  ##
  # Encapsulates the overridable settings for a particular RPC call.
  #
  # @!attribute [r] timeout
  #   @return [Numeric, nil]
  # @!attribute [r] metadata
  #   @return [Hash]
  # @!attribute [r] retry_policy
  #   @return [RetryPolicy, Object]
  #
  class CallOptions
    attr_reader :timeout
    attr_reader :metadata
    attr_reader :retry_policy

    ##
    # Create a new Options object instance.
    #
    # @param timeout [Numeric] The client-side timeout for RPC calls.
    # @param metadata [Hash] The request header params.
    # @param retry_policy [Hash, RetryPolicy, Proc] The policy for error retry. A Hash can be provided to
    #   customize the policy object, using keys that match the arguments for {RetryPolicy.initialize}.
    #
    #   A Proc object can also be provided. The Proc should accept an error as an argument, and return `true` if the
    #   error should be retried or `false` if not. If the error is to be retried, the Proc object must also block
    #   with an incremental delay before returning `true`.
    #
    def initialize timeout: nil, metadata: nil, retry_policy: nil
      # Converts hash and nil to a policy object
      retry_policy = RetryPolicy.new(**retry_policy.to_h) if retry_policy.respond_to? :to_h

      @timeout = timeout # allow to be nil so it can be overridden
      @metadata = metadata.to_h # Ensure always hash, even for nil
      @retry_policy = retry_policy
    end

    ##
    # @private
    # Apply default values to the options object. This does not replace user-provided values, it only overrides
    # empty values.
    #
    # @param timeout [Numeric] The client-side timeout for RPC calls.
    # @param metadata [Hash] the request header params.
    # @param retry_policy [Hash] The policy for error retry. keys must match the arguments for
    #   {RetryPolicy.initialize}.
    #
    def apply_defaults timeout: nil, metadata: nil, retry_policy: nil
      @timeout ||= timeout
      @metadata = metadata.merge @metadata if metadata
      @retry_policy.apply_defaults retry_policy if @retry_policy.respond_to? :apply_defaults
    end

    ##
    # Convert to hash form.
    #
    # @return [Hash]
    #
    def to_h
      {
        timeout:      timeout,
        metadata:     metadata,
        retry_policy: retry_policy
      }
    end

    ##
    # Return a new CallOptions with the given modifications. The current object
    # is not modified.
    #
    # @param kwargs [keywords] Updated fields. See {#initialize} for details.
    # @return [CallOptions] A new CallOptions object.
    #
    def merge **kwargs
      kwargs = to_h.merge kwargs
      CallOptions.new(**kwargs)
    end

    # @private Equality test
    def eql? other
      other.is_a?(CallOptions) &&
        other.timeout == timeout &&
        other.metadata == metadata &&
        other.retry_policy == retry_policy
    end
    alias == eql?

    # @private Hash code
    def hash
      to_h.hash
    end
  end
end
