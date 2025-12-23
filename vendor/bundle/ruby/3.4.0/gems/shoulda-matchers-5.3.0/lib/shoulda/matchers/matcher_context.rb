module Shoulda
  module Matchers
    # @private
    class MatcherContext
      def initialize(context)
        @context = context
      end

      def subject_is_a_class?
        if inside_a_shoulda_context_project? && outside_a_should_block?
          assume_that_subject_is_not_a_class
        else
          context.subject.is_a?(Class)
        end
      end

      protected

      attr_reader :context

      private

      def inside_a_shoulda_context_project?
        defined?(Shoulda::Context)
      end

      def outside_a_should_block?
        context.is_a?(Class)
      end

      def assume_that_subject_is_not_a_class
        false
      end
    end
  end
end
