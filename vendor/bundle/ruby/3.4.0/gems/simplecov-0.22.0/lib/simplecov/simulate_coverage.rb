# frozen_string_literal: true

module SimpleCov
  #
  # Responsible for producing file coverage metrics.
  #
  module SimulateCoverage
  module_function

    #
    # Simulate normal file coverage report on
    # ruby 2.5 and return similar hash with lines and branches keys
    #
    # Happens when a file wasn't required but still tracked.
    #
    # @return [Hash]
    #
    def call(absolute_path)
      lines = File.foreach(absolute_path)

      {
        "lines" => LinesClassifier.new.classify(lines),
        # we don't want to parse branches ourselves...
        # requiring files can have side effects and we don't want to trigger that
        "branches" => {}
      }
    end
  end
end
