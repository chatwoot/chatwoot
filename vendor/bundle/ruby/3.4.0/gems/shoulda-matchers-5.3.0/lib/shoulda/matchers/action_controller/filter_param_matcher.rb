module Shoulda
  module Matchers
    module ActionController
      # The `filter_param` matcher is used to test parameter filtering
      # configuration. Specifically, it asserts that the given parameter is
      # present in `config.filter_parameters`.
      #
      #     class MyApplication < Rails::Application
      #       config.filter_parameters << :secret_key
      #     end
      #
      #     # RSpec
      #     RSpec.describe ApplicationController, type: :controller do
      #       it { should filter_param(:secret_key) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ApplicationControllerTest < ActionController::TestCase
      #       should filter_param(:secret_key)
      #     end
      #
      # @return [FilterParamMatcher]
      #
      def filter_param(key)
        FilterParamMatcher.new(key)
      end

      # @private
      class FilterParamMatcher
        def initialize(key)
          @key = key
        end

        def matches?(_controller)
          filters_key?
        end

        def failure_message
          "Expected #{@key} to be filtered; filtered keys:"\
            " #{filtered_keys.join(', ')}"
        end

        def failure_message_when_negated
          "Did not expect #{@key} to be filtered"
        end

        def description
          "filter #{@key}"
        end

        private

        def filters_key?
          filtered_keys.any? do |filter|
            case filter
            when Regexp
              filter =~ @key
            else
              filter == @key
            end
          end
        end

        def filtered_keys
          Rails.application.config.filter_parameters
        end
      end
    end
  end
end
