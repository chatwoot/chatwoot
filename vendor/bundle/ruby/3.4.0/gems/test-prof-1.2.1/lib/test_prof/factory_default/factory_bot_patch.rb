# frozen_string_literal: true

module TestProf
  module FactoryDefault # :nodoc: all
    module RunnerExt
      refine TestProf::FactoryBot::FactoryRunner do
        attr_reader :name, :traits, :overrides
      end
    end

    using RunnerExt

    module StrategyExt
      def association(runner)
        FactoryDefault.get(runner.name, runner.traits, runner.overrides) ||
          FactoryDefault.profiler.instrument(runner.name, runner.traits, runner.overrides) { super }
      end
    end
  end
end
