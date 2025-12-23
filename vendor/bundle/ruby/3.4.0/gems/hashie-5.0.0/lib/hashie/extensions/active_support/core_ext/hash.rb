module Hashie
  module Extensions
    module ActiveSupport
      module CoreExt
        module Hash
          def except(*keys)
            string_keys = keys.map { |key| convert_key(key) }
            super(*string_keys)
          end
        end
      end
    end
  end
end
