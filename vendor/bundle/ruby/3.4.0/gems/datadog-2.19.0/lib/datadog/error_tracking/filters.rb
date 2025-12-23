# frozen_string_literal: true

module Datadog
  module ErrorTracking
    # Based on configuration, the TracePoint listening to :rescue or :raise
    # may report more handled errors than we want to report. Therefore we need
    # a function to filter the events. As the filter function both depends
    # on configuration and is called numerous time, we generate it during
    # during the initialization of the feature to have the best performance
    # possible.
    #
    # @api private
    module Filters
      module_function

      def get_gem_name(file_path)
        regex = %r{gems/([^/]+)-\d}
        regex_match = regex.match(file_path)
        return unless regex_match

        gem_name = regex_match[1]

        begin
          Gem::Specification.find_by_name(gem_name) # steep:ignore
        rescue Gem::MissingSpecError
          nil
        end
      end

      def user_code?(file_path)
        !get_gem_name(file_path)
      end

      def datadog_code?(file_path)
        file_path.include?('lib/datadog/')
      end

      def third_party_code?(file_path)
        gem_name = get_gem_name(file_path)
        gem_name && gem_name != "datadog"
      end

      def file_included?(file_path, instrumented_files)
        instrumented_files.include?(file_path)
      end

      # Generate the proc used in the TracePoint
      def generate_filter(to_instrument_scope, handled_errors_include = nil)
        case to_instrument_scope
        # If DD_ERROR_TRACKING_HANDLED_ERRORS is set
        when 'all'
          proc { |file_path| !datadog_code?(file_path) }
        when 'user'
          # If DD_ERROR_TRACKING_HANDLED_ERRORS_INCLUDE is set
          if handled_errors_include
            proc { |file_path|
              user_code?(file_path) || file_included?(file_path, handled_errors_include)
            }
          else
            proc { |file_path| user_code?(file_path) }
          end
        when 'third_party'
          if handled_errors_include
            proc { |file_path|
              third_party_code?(file_path) || file_included?(file_path, handled_errors_include)
            }
          else
            proc { |file_path| third_party_code?(file_path) }
          end
        else
          # If only DD_ERROR_TRACKING_HANDLED_ERRORS_INCLUDE is set
          proc { |file_path| file_included?(file_path, handled_errors_include) }
        end
      end
    end
  end
end
