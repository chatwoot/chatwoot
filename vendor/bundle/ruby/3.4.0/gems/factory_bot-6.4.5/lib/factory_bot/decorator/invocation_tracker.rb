module FactoryBot
  class Decorator
    class InvocationTracker < Decorator
      def initialize(component)
        super
        @invoked_methods = []
      end

      def method_missing(name, *args, &block) # rubocop:disable Style/MissingRespondToMissing
        @invoked_methods << name
        super
      end
      ruby2_keywords :method_missing if respond_to?(:ruby2_keywords, true)

      def __invoked_methods__
        @invoked_methods.uniq
      end
    end
  end
end
