module Shoulda
  module Matchers
    module Doublespeak
      # @private
      class ObjectDouble < BasicObject
        attr_reader :calls

        def initialize
          @calls = []
          @calls_by_method_name = {}
        end

        def calls_to(method_name)
          @calls_by_method_name[method_name] || []
        end

        def respond_to?(_name, _include_private = nil)
          true
        end

        def respond_to_missing?(_name, _include_all)
          true
        end

        def method_missing(method_name, *args, &block)
          call = MethodCall.new(
            method_name: method_name,
            args: args,
            block: block,
            caller: ::Kernel.caller,
          )
          calls << call
          (calls_by_method_name[method_name] ||= []) << call
          nil
        end

        protected

        attr_reader :calls_by_method_name
      end
    end
  end
end
