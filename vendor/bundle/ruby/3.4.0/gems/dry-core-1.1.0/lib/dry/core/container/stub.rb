# frozen_string_literal: true

module Dry
  module Core
    class Container
      module Stub
        # Overrides resolve to look into stubbed keys first
        #
        # @api public
        def resolve(key)
          _stubs.fetch(key.to_s) { super }
        end

        # Add a stub to the container
        def stub(key, value, &block)
          unless key?(key)
            raise ::ArgumentError, "cannot stub #{key.to_s.inspect} - no such key in container"
          end

          _stubs[key.to_s] = value

          if block
            yield
            unstub(key)
          end

          self
        end

        # Remove stubbed keys from the container
        def unstub(*keys)
          keys = _stubs.keys if keys.empty?
          keys.each { |key| _stubs.delete(key.to_s) }
        end

        # Stubs have already been enabled turning this into a noop
        def enable_stubs!
          # DO NOTHING
        end

        private

        # Stubs container
        def _stubs
          @_stubs ||= {}
        end
      end

      module Mixin
        # Enable stubbing functionality into the current container
        def enable_stubs!
          extend ::Dry::Core::Container::Stub
        end
      end
    end
  end
end
