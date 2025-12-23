module Shoulda
  module Matchers
    module Integrations
      # @private
      class Registry
        def register(klass, name)
          registry[name] = klass
        end

        def find!(name)
          find_class!(name).new
        end

        private

        def registry
          @_registry ||= {}
        end

        def find_class!(name)
          registry.fetch(name) do
            raise ArgumentError, "'#{name}' is not registered"
          end
        end
      end
    end
  end
end
