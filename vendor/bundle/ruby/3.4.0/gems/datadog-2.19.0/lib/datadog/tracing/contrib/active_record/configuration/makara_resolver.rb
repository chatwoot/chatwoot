# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ActiveRecord
        module Configuration
          # The `makara` gem has the concept of **role**, which can be
          # inferred from the configuration `name`, in the form of:
          # `master/0`, `replica/0`, `replica/1`, etc.
          # The first part of this string is the database role.
          #
          # This allows the matching of a connection based on its role,
          # instead of connection-specific information.
          module MakaraResolver
            def normalize_for_config(active_record_config)
              hash = super
              hash[:makara_role] = active_record_config[:makara_role]
              hash
            end

            def normalize_for_resolve(active_record_config)
              hash = super

              if active_record_config[:name].is_a?(String)
                hash[:makara_role] = active_record_config[:name].split('/')[0].to_s
              end

              hash
            end
          end
        end
      end
    end
  end
end
