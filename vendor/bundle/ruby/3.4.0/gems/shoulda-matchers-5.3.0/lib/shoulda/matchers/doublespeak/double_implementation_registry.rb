module Shoulda
  module Matchers
    module Doublespeak
      # @private
      module DoubleImplementationRegistry
        class << self
          def find(type)
            find_class!(type).create
          end

          def register(klass, type)
            registry[type] = klass
          end

          private

          def find_class!(type)
            registry.fetch(type) do
              raise ArgumentError, 'No double implementation class found for'\
                " '#{type}'"
            end
          end

          def registry
            @_registry ||= {}
          end
        end
      end
    end
  end
end
