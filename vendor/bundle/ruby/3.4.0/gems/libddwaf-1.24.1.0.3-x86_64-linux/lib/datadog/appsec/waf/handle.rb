# frozen_string_literal: true

module Datadog
  module AppSec
    module WAF
      # Ruby representation of the ddwaf_handle in libddwaf
      # See https://github.com/DataDog/libddwaf/blob/10e3a1dfc7bc9bb8ab11a09a9f8b6b339eaf3271/BINDING_IMPL_NOTES.md?plain=1#L4-L19
      class Handle
        def initialize(handle_ptr)
          @handle_ptr = handle_ptr
        end

        # Destroys the WAF handle and sets the pointer to nil.
        #
        # The instance becomes unusable after this method is called.
        def finalize!
          handle_ptr_to_destroy = @handle_ptr
          @handle_ptr = nil

          LibDDWAF.ddwaf_destroy(handle_ptr_to_destroy)
        end

        # Builds a WAF context.
        #
        # @raise [LibDDWAFError] if libddwaf could not create the context.
        # @return [Handle] the WAF handle
        def build_context
          ensure_pointer_presence!

          context_obj = LibDDWAF.ddwaf_context_init(@handle_ptr)
          raise LibDDWAFError, "Could not create context" if context_obj.null?

          Context.new(context_obj)
        end

        # Returns the list of known addresses in the WAF handle.
        #
        # @return [Array<String>] the list of known addresses
        def known_addresses
          ensure_pointer_presence!

          count = LibDDWAF::UInt32Ptr.new
          list = LibDDWAF.ddwaf_known_addresses(@handle_ptr, count)

          return [] if count == 0 # list is null

          list.get_array_of_string(0, count[:value])
        end

        private

        def ensure_pointer_presence!
          return if @handle_ptr

          raise InstanceFinalizedError, "Cannot use WAF handle after it has been finalized"
        end
      end
    end
  end
end
