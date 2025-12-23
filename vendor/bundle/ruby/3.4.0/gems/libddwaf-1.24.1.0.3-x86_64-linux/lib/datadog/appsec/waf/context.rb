# frozen_string_literal: true

module Datadog
  module AppSec
    module WAF
      # Ruby representation of the ddwaf_context in libddwaf
      # See https://github.com/DataDog/libddwaf/blob/10e3a1dfc7bc9bb8ab11a09a9f8b6b339eaf3271/BINDING_IMPL_NOTES.md?plain=1#L125-L158
      class Context
        RESULT_CODE = {
          ddwaf_ok: :ok,
          ddwaf_match: :match,
          ddwaf_err_internal: :err_internal,
          ddwaf_err_invalid_object: :err_invalid_object,
          ddwaf_err_invalid_argument: :err_invalid_argument
        }.freeze

        def initialize(context_ptr)
          @context_ptr = context_ptr
        end

        # Destroys the WAF context and sets the pointer to nil.
        #
        # The instance becomes unusable after this method is called.
        def finalize!
          context_ptr_to_destroy = @context_ptr
          @context_ptr = nil

          retained.each do |retained_obj|
            next unless retained_obj.is_a?(LibDDWAF::Object)

            LibDDWAF.ddwaf_object_free(retained_obj)
          end

          retained.clear
          LibDDWAF.ddwaf_context_destroy(context_ptr_to_destroy)
        end

        # Runs the WAF context with the given persistent and ephemeral data.
        #
        # @raise [ConversionError] if the conversion of persistent or ephemeral data fails
        # @raise [LibDDWAFError] if libddwaf could not create the result object
        #
        # @return [Result] the result of the WAF run
        def run(persistent_data, ephemeral_data, timeout = LibDDWAF::DDWAF_RUN_TIMEOUT)
          ensure_pointer_presence!

          persistent_data_obj = Converter.ruby_to_object(
            persistent_data,
            max_container_size: LibDDWAF::DDWAF_MAX_CONTAINER_SIZE,
            max_container_depth: LibDDWAF::DDWAF_MAX_CONTAINER_DEPTH,
            max_string_length: LibDDWAF::DDWAF_MAX_STRING_LENGTH,
            coerce: false
          )
          if persistent_data_obj.null?
            raise ConversionError, "Could not convert persistent data: #{persistent_data.inspect}"
          end

          # retain C objects in memory for subsequent calls to run
          retain(persistent_data_obj)

          ephemeral_data_obj = Converter.ruby_to_object(
            ephemeral_data,
            max_container_size: LibDDWAF::DDWAF_MAX_CONTAINER_SIZE,
            max_container_depth: LibDDWAF::DDWAF_MAX_CONTAINER_DEPTH,
            max_string_length: LibDDWAF::DDWAF_MAX_STRING_LENGTH,
            coerce: false
          )
          if ephemeral_data_obj.null?
            raise ConversionError, "Could not convert ephemeral data: #{ephemeral_data.inspect}"
          end

          result_obj = LibDDWAF::Result.new
          raise LibDDWAFError, "Could not create result object" if result_obj.null?

          code = LibDDWAF.ddwaf_run(@context_ptr, persistent_data_obj, ephemeral_data_obj, result_obj, timeout)

          Result.new(
            RESULT_CODE[code],
            Converter.object_to_ruby(result_obj[:events]),
            result_obj[:total_runtime],
            result_obj[:timeout],
            Converter.object_to_ruby(result_obj[:actions]),
            Converter.object_to_ruby(result_obj[:derivatives])
          )
        ensure
          LibDDWAF.ddwaf_result_free(result_obj) if result_obj
          LibDDWAF.ddwaf_object_free(ephemeral_data_obj) if ephemeral_data_obj
        end

        private

        def ensure_pointer_presence!
          return if @context_ptr

          raise InstanceFinalizedError, "Cannot use WAF context after it has been finalized"
        end

        def retained
          @retained ||= []
        end

        def retain(object)
          retained << object
        end

        def release(object)
          retained.delete(object)
        end
      end
    end
  end
end
