# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Utils
        # Common database-related utility functions.
        module Database
          VENDOR_DEFAULT = 'defaultdb'
          VENDOR_POSTGRES = 'postgres'
          VENDOR_SQLITE = 'sqlite'

          module_function

          def normalize_vendor(vendor)
            case vendor
            when nil
              VENDOR_DEFAULT
            when 'postgresql'
              VENDOR_POSTGRES
            when 'sqlite3'
              VENDOR_SQLITE
            else
              vendor
            end
          end
        end
      end
    end
  end
end
