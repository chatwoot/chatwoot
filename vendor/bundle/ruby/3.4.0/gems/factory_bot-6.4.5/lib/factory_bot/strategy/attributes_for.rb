module FactoryBot
  module Strategy
    class AttributesFor
      def association(runner)
        runner.run(:null)
      end

      def result(evaluation)
        evaluation.hash
      end

      def to_sym
        :attributes_for
      end
    end
  end
end
