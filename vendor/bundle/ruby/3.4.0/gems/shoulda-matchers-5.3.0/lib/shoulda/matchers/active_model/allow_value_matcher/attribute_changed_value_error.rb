module Shoulda
  module Matchers
    module ActiveModel
      class AllowValueMatcher
        # @private
        class AttributeChangedValueError < Shoulda::Matchers::Error
          attr_accessor :matcher_name, :model, :attribute_name, :value_written,
            :value_read

          def message
            Shoulda::Matchers.word_wrap <<-MESSAGE
The #{matcher_name} matcher attempted to set :#{attribute_name} on
#{model.name} to #{value_written.inspect}, but when the attribute was
read back, it had stored #{value_read.inspect} instead.

This creates a problem because it means that the model is behaving in a
way that is interfering with the test -- there's a mismatch between the
test that you wrote and test that we actually ran.

There are a couple of reasons why this could be happening:

* ActiveRecord is typecasting the incoming value.
* The writer method for :#{attribute_name} has been overridden so that
  incoming values are changed in some way.

If this exception makes sense to you and you wish to bypass it, try
adding the `ignoring_interference_by_writer` qualifier onto the end of
your matcher. If the test still does not pass after that, then you may
need to do something different.

If you need help, feel free to ask a question on the shoulda-matchers
issues list:

https://github.com/thoughtbot/shoulda-matchers/issues
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
