require "test_helper"

class DocsOptionTest < Minitest::Spec
  it do
    #:method
    option = Trailblazer::Option(:object_id)
    option.(exec_context: Object.new) # => 1234567
    #:method end

    #:lambda
    option = Trailblazer::Option(-> { object_id })
    option.(exec_context: Object.new) # => 1234567
    #:lambda end

    #:module
    class CallMe
      def self.call(message:, **options)
        message
      end
    end

    option = Trailblazer::Option(CallMe)
    option.(keyword_arguments: { message: "hello!" }, exec_context: nil) # => "hello!"
    #:module end
  end
end
