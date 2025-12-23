module FactoryBot
  module Strategy
    class Build
      def association(runner)
        runner.run
      end

      def result(evaluation)
        evaluation.object.tap do |instance|
          evaluation.notify(:after_build, instance)
        end
      end

      def to_sym
        :build
      end
    end
  end
end
