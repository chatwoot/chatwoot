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

require "gapic/generic_lro/base_operation"
require "gapic/operation/retry_policy"

module Gapic
  module GenericLRO
    ##
    # A class used to wrap the longrunning operation objects, including the nonstandard ones
    # (`nonstandard` meaning not conforming to the AIP-151).
    # It provides helper methods to poll and check for status of these operations.
    #
    class Operation < Gapic::GenericLRO::BaseOperation
      ##
      # @param operation [Object] The long-running operation object that is returned by the initial method call.
      #
      # @param client [Object] The client that handles the polling for the longrunning operation.
      #
      # @param polling_method_name [String] The name of the methods on the client that polls the longrunning operation.
      #
      # @param operation_status_field [String] The name of the `status` field in the underlying long-running operation
      #   object. The `status` field signals that the operation has finished. It should either contain symbols, and
      #   be set to `:DONE` when finished or contain a boolean and be set to `true` when finished.
      #
      # @param request_values [Map<String, String>] The values that are to be copied from the request that
      #   triggered the longrunning operation, into the request that polls for the longrunning operation.
      #   The format is `name of the request field` -> `value`
      #
      # @param operation_name_field [String, nil] The name of the `name` field in the underlying long-running operation
      #   object. Optional.
      #
      # @param operation_err_field [String, nil] The name of the `error` field in the underlying long-running operation
      #   object. The `error` field should be a message-type, and have same semantics as `google.rpc.Status`, including
      #   an integer `code` subfield, that carries an error code. If the `operation_err_field` field is given,
      #   the `operation_err_code_field` and `operation_err_msg_field` parameters are ignored. Optional.
      #
      # @param operation_err_code_field [String, nil] The name of the `error_code` field in the underlying
      #   long-running operation object. It is ignored if `operation_err_field` is given. Optional.
      #
      # @param operation_err_msg_field [String, nil] The name of the `error_message` field in the underlying
      #   long-running operation object. It is ignored if `operation_err_field` is given. Optional.
      #
      # @param operation_copy_fields [Map<String, String>] The map of the fields that need to be copied from the
      #   long-running operation object that the polling method returns to the polling request.
      #   The format is `name of the operation object field` -> `name of the request field` (`from` -> `to`)
      #
      # @param options [Gapic::CallOptions] call options for this operation
      #
      def initialize operation, client:, polling_method_name:, operation_status_field:,
                     request_values: {}, operation_name_field: nil, operation_err_field: nil,
                     operation_err_code_field: nil, operation_err_msg_field: nil, operation_copy_fields: {},
                     options: {}
        @client = client
        @polling_method_name = polling_method_name
        @operation_status_field = operation_status_field

        @request_values = request_values || {}

        @operation_name_field = operation_name_field
        @operation_err_field = operation_err_field
        @operation_err_code_field = operation_err_code_field
        @operation_err_msg_field = operation_err_msg_field

        @operation_copy_fields = operation_copy_fields || {}

        @on_done_callbacks = []
        @on_reload_callbacks = []
        @options = options || {}

        super operation
      end

      ##
      # If the operation is done, returns the response. If the operation response is an error, the error will be
      # returned. Otherwise returns nil.
      #
      # @return [Object, nil] The result of the operation or an error.
      #
      def results
        return error if error?
        response if response?
      end

      ##
      # Returns the name of the operation, if specified.
      #
      # @return [String, nil] The name of the operation.
      #
      def name
        return nil if @operation_name_field.nil?
        operation.send @operation_name_field if operation.respond_to? @operation_name_field
      end

      ##
      # Checks if the operation is done. This does not send a new api call, but checks the result of the previous api
      # call to see if done.
      #
      # @return [Boolean] Whether the operation is done.
      #
      def done?
        return status if [true, false].include? status

        status == :DONE
      end

      ##
      # Checks if the operation is done and the result is not an error. If the operation is not finished then this will
      # return false.
      #
      # @return [Boolean] Whether a response has been returned.
      #
      def response?
        done? && !error?
      end

      ##
      # If the operation is completed successfully, returns the underlying operation object, otherwise returns nil.
      #
      # @return [Object, nil] The response of the operation.
      def response
        operation if response?
      end

      ##
      # Checks if the operation is done and the result is an error. If the operation is not finished then this will
      # return false.
      #
      # @return [Boolean] Whether an error has been returned.
      #
      def error?
        no_error_code = error_code.nil? || error_code.zero?
        done? && !(err.nil? && no_error_code)
      end

      ##
      # If the operation response is an error, the error will be returned, otherwise returns nil.
      #
      # @return [Object, nil] The error object.
      #
      def error
        return unless error?
        err || GenericError.new(error_code, error_msg)
      end

      ##
      # Reloads the operation object.
      #
      # @param options [Gapic::CallOptions, Hash] The options for making the RPC call. A Hash can be provided
      # to customize the options object, using keys that match the arguments for {Gapic::CallOptions.new}.
      #
      # @return [Gapic::GenericLRO::Operation] Since this method changes internal state, it returns itself.
      #
      def reload! options: nil
        return self if done?

        @on_reload_callbacks.each { |proc| proc.call self }

        request_hash = @request_values.transform_keys(&:to_sym)
        @operation_copy_fields.each do |field_from, field_to|
          request_hash[field_to.to_sym] = operation.send field_from.to_s if operation.respond_to? field_from.to_s
        end

        options = merge_options options, @options

        ops = @client.send @polling_method_name, request_hash, options
        ops = ops.operation if ops.is_a? Gapic::GenericLRO::BaseOperation

        self.operation = ops

        if done?
          @on_reload_callbacks.clear
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
      # @yieldparam operation [Gapic::GenericLRO::Operation] Yields the finished Operation.
      #
      def wait_until_done! retry_policy: nil
        retry_policy = ::Gapic::Operation::RetryPolicy.new(**retry_policy) if retry_policy.is_a? Hash
        retry_policy ||= ::Gapic::Operation::RetryPolicy.new

        until done?
          reload!
          break unless retry_policy.call
        end

        yield self if block_given?

        self
      end

      ##
      # Registers a callback to be run when an operation is being reloaded. If the operation has completed
      # prior to a call to this function the callback will NOT be called or registered.
      #
      # @yieldparam operation [Gapic::Operation] Yields the finished Operation.
      #
      def on_reload &block
        return if done?
        @on_reload_callbacks.push block
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

      private

      ##
      # @return [String, Boolean, nil] A status, whether operation is Done,
      #   as either a boolean (`true` === Done) or a symbol (`:DONE` === Done)
      #
      def status
        return nil if @operation_status_field.nil?
        operation.send @operation_status_field
      end

      ##
      # @return [String, nil] An error message if the error message field is specified
      #
      def err
        return nil if @operation_err_field.nil?
        operation.send @operation_err_field if operation.respond_to? @operation_err_field
      end

      ##
      # @return [String, nil] An error code if the error code field is specified
      #
      def error_code
        return nil if @operation_err_code_field.nil?
        operation.send @operation_err_code_field if operation.respond_to? @operation_err_code_field
      end

      ##
      # @return [String, nil] An error message if the error message field is specified
      #
      def error_msg
        return nil if @operation_err_msg_field.nil?
        operation.send @operation_err_msg_field if operation.respond_to? @operation_err_msg_field
      end

      ##
      # Merges options given to the method with a baseline Gapic::Options object
      #
      # @param method_opts [Gapic::CallOptions, Hash] The options for making the RPC call given to a method invocation.
      #   A Hash can be provided to customize the options object, using keys that match the arguments
      #   for {Gapic::CallOptions.new}.
      #
      # @param baseline_opts [Gapic::CallOptions, Hash] The baseline options for making the RPC call.
      #   A Hash can be provided to customize the options object, using keys that match the arguments
      #   for {Gapic::CallOptions.new}.
      #
      def merge_options method_opts, baseline_opts
        options = if method_opts.respond_to? :to_h
                    method_opts.to_h.merge baseline_opts.to_h
                  else
                    baseline_opts.to_h
                  end

        Gapic::CallOptions.new(**options)
      end

      ##
      # Represents a generic error that a generic LRO can report
      #
      # @!attribute [r] code
      #   @return [String] An error code
      #
      # @!attribute [r] message
      #   @return [String] An error message
      #
      class GenericError
        attr_accessor :code
        attr_accessor :message

        ##
        # @param code [String] An error code
        # @param message [String] An error message
        def initialize code, message
          @code = code
          @message = message
        end
      end

      protected

      ##
      # @private
      # @return [Object] The client that handles the polling for the longrunning operation.
      attr_accessor :client
    end
  end
end
