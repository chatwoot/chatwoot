module FactoryBot
  module Strategy
    class Null
      def association(runner)
      end

      def result(evaluation)
      end

      def to_sym
        :null
      end
    end
  end
end
