module Shoulda
  module Matchers
    module ActiveModel
      class AllowValueMatcher
        # @private
        class AttributeDoesNotExistError < Shoulda::Matchers::Error
          attr_accessor :model, :attribute_name, :value

          def message
            Shoulda::Matchers.word_wrap <<-MESSAGE
The matcher attempted to set :#{attribute_name} on the #{model.name} to
#{value.inspect}, but that attribute does not exist.
            MESSAGE
          end

          def successful?
            false
          end
        end
      end
    end
  end
end
