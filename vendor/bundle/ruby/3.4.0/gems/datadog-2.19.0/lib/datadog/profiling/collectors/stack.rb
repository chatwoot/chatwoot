# frozen_string_literal: true

module Datadog
  module Profiling
    module Collectors
      # Used to gather a stack trace from a given Ruby thread. Stores its output on a `StackRecorder`.
      #
      # This class is not empty; all of this class is implemented as native code.
      class Stack # rubocop:disable Lint/EmptyClass
      end
    end
  end
end
