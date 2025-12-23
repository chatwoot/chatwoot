module Shoulda
  module Matchers
    module ActionController
      # @private
      class SessionStore
        attr_accessor :controller

        def name
          'session'
        end

        def has_key?(key)
          session.key?(key)
        end

        def has_value?(expected_value)
          session.values.any? do |actual_value|
            expected_value === actual_value
          end
        end

        def empty?
          session.empty?
        end

        private

        def session
          controller.session
        end
      end
    end
  end
end
