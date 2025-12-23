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

require "gapic/operation/retry_policy"
require "google/protobuf/well_known_types"

module Gapic
  # A class used to wrap Google::Longrunning::Operation objects. This class provides helper methods to check the
  # status of an Operation
  #
  # @example Checking Operation status
  #   # this example assumes both api_client and operations_client
  #   # already exist.
  #   require "gapic/operation"
  #
  #   op = Gapic::Operation.new(
  #     api_client.method_that_returns_longrunning_operation(),
  #     operations_client,
  #     Google::Example::ResultType,
  #     Google::Example::MetadataType
  #   )
  #
  #   op.done? # => false
  #   op.reload! # => operation completed
  #
  #   if op.done?
  #     results = op.results
  #     handle_error(results) if op.error?
  #     # Handle results.
  #   end
  #
  # @example Working with callbacks
  #   # this example assumes both api_client and operations_client
  #   # already exist.
  #   require "gapic/operation"
  #
  #   op = Gapic::Operation.new(
  #     api_client.method_that_returns_longrunning_operation(),
  #     operations_client,
  #     Google::Example::ResultType,
  #     Google::Example::MetadataType
  #   )
  #
  #   # Register a callback to be run when an operation is done.
  #   op.on_done do |operation|
  #     raise operation.results.message if operation.error?
  #     # process(operation.results)
  #     # process(operation.metadata)
  #   end
  #
  #   # Reload the operation running callbacks if operation completed.
  #   op.reload!
  #
  #   # Or block until the operation completes, passing a block to be called
  #   # on completion.
  #   op.wait_until_done! do |operation|
  #     raise operation.results.message if operation.error?
  #     # process(operation.results)
  #     # process(operation.rmetadata)
  #   end
  #
  # @attribute [r] grpc_op
  #   @return [Google::Longrunning::Operation] The wrapped grpc
  #     operation object.
  class Operation
    attr_reader :grpc_op

    ##
    # @param grpc_op [Google::Longrunning::Operation] The inital longrunning operation.
    # @param client [Google::Longrunning::OperationsClient] The client that handles the grpc operations.
    # @param result_type [Class] The class type to be unpacked from the result. If not provided the class type will be
    #   looked up. Optional.
    # @param metadata_type [Class] The class type to be unpacked from the metadata. If not provided the class type
    #   will be looked up. Optional.
    # @param options [Gapic::CallOptions] call options for this operation
    #
    def initialize grpc_op, client, result_type: nil, metadata_type: nil, options: {}
      @grpc_op = grpc_op
      @client = client
      @result_type = result_type
      @metadata_type = metadata_type
      @on_done_callbacks = []
      @options = options
    end

    ##
    # If the operation is done, returns the response. If the operation response is an error, the error will be
    # returned. Otherwise returns nil.
    #
    # @return [Object, Google::Rpc::Status, nil] The result of the operation. If it is an error a
    #   `Google::Rpc::Status` will be returned.
    def results
      return error if error?
      response if response?
    end

    ##
    # Returns the server-assigned name of the operation, which is only unique within the same service that originally
    # returns it. If you use the default HTTP mapping, the name should have the format of operations/some/unique/name.
    #
    # @return [String] The name of the operation.
    #
    def name
      @grpc_op.name
    end

    ##
    # Returns the metadata of an operation. If a type is provided, the metadata will be unpacked using the type
    # provided; returning nil if the metadata is not of the type provided. If the type is not of provided, the
    # metadata will be unpacked using the metadata's type_url if the type_url is found in the
    # `Google::Protobuf::DescriptorPool.generated_pool`. If the type cannot be found the raw metadata is retuned.
    #
    # @return [Object, nil] The metadata of the operation. Can be nil.
    #
    def metadata
      return if @grpc_op.metadata.nil?

      return @grpc_op.metadata.unpack @metadata_type if @metadata_type

      descriptor = Google::Protobuf::DescriptorPool.generated_pool.lookup @grpc_op.metadata.type_name

      return @grpc_op.metadata.unpack descriptor.msgclass if descriptor

      @grpc_op.metadata
    end

    ##
    # Checks if the operation is done. This does not send a new api call, but checks the result of the previous api
    # call to see if done.
    #
    # @return [Boolean] Whether the operation is done.
    #
    def done?
      @grpc_op.done
    end

    ##
    # Checks if the operation is done and the result is a response. If the operation is not finished then this will
    # return false.
    #
    # @return [Boolean] Whether a response has been returned.
    #
    def response?
      done? ? @grpc_op.result == :response : false
    end

    ##
    # If the operation is done, returns the response, otherwise returns nil.
    #
    # @return [Object, nil] The response of the operation.
    def response
      return unless response?

      return @grpc_op.response.unpack @result_type if @result_type

      descriptor = Google::Protobuf::DescriptorPool.generated_pool.lookup @grpc_op.response.type_name

      return @grpc_op.response.unpack descriptor.msgclass if descriptor

      @grpc_op.response
    end

    ##
    # Checks if the operation is done and the result is an error. If the operation is not finished then this will
    # return false.
    #
    # @return [Boolean] Whether an error has been returned.
    #
    def error?
      done? ? @grpc_op.result == :error : false
    end

    ##
    # If the operation response is an error, the error will be returned, otherwise returns nil.
    #
    # @return [Google::Rpc::Status, nil] The error object.
    #
    def error
      @grpc_op.error if error?
    end

    ##
    # Cancels the operation.
    #
    # @param options [Gapic::CallOptions, Hash] The options for making the RPC call. A Hash can be provided to customize
    #   the options object, using keys that match the arguments for {Gapic::CallOptions.new}.
    #
    def cancel options: nil
      # Converts hash and nil to an options object
      options = Gapic::CallOptions.new(**options.to_h) if options.respond_to? :to_h

      @client.cancel_operation({ name: @grpc_op.name }, options)
    end

    ##
    # Deletes the operation.
    #
    # @param options [Gapic::CallOptions, Hash] The options for making the RPC call. A Hash can be provided to customize
    #   the options object, using keys that match the arguments for {Gapic::CallOptions.new}.
    #
    def delete options: nil
      # Converts hash and nil to an options object
      options = Gapic::CallOptions.new(**options.to_h) if options.respond_to? :to_h

      @client.delete_operation({ name: @grpc_op.name }, options)
    end

    ##
    # Reloads the operation object.
    #
    # @param options [Gapic::CallOptions, Hash] The options for making the RPC call. A Hash can be provided to customize
    #   the options object, using keys that match the arguments for {Gapic::CallOptions.new}.
    #
    # @return [Gapic::Operation] Since this method changes internal state, it returns itself.
    #
    def reload! options: nil
      options = if options.respond_to? :to_h
                  options.to_h.merge @options.to_h
                else
                  @options.to_h
                end
      options = Gapic::CallOptions.new(**options)
      gax_op = @client.get_operation({ name: @grpc_op.name }, options)
      @grpc_op = gax_op.grpc_op

      if done?
        @on_done_callbacks.each { |proc| proc.call self }
        @on_done_callbacks.clear
      end

      self
    end
    alias refresh! reload!

    ##
    # Blocking method to wait until the operation has completed or the maximum timeout has been reached. Upon
    # completion, registered callbacks will be called, then - if a block is given - the block will be called.
    #
    # @param retry_policy [RetryPolicy, Hash, Proc] The policy for retry. A custom proc that takes the error as an
    #   argument and blocks can also be provided.
    #
    # @yieldparam operation [Gapic::Operation] Yields the finished Operation.
    #
    def wait_until_done! retry_policy: nil
      retry_policy = RetryPolicy.new(**retry_policy) if retry_policy.is_a? Hash
      retry_policy ||= RetryPolicy.new

      until done?
        reload!
        break unless retry_policy.call
      end

      yield self if block_given?

      self
    end

    ##
    # Registers a callback to be run when a refreshed operation is marked as done. If the operation has completed
    # prior to a call to this function the callback will be called instead of registered.
    #
    # @yieldparam operation [Gapic::Operation] Yields the finished Operation.
    #
    def on_done &block
      if done?
        yield self
      else
        @on_done_callbacks.push block
      end
    end
  end
end
