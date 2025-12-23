module Shoulda
  module Matchers
    module ActiveRecord
      # @private
      module Uniqueness
        # @private
        class Namespace
          def initialize(constant)
            @constant = constant
          end

          def has?(name)
            constant.const_defined?(name)
          end

          def set(name, value)
            constant.const_set(name, value)
          end

          def clear
            constant.constants.each do |child_constant|
              constant.__send__(:remove_const, child_constant)
            end
          end

          def to_s
            constant.to_s
          end

          protected

          attr_reader :constant
        end
      end
    end
  end
end
