# frozen_string_literal: true

require_relative '../core/utils/forking'

module Datadog
  module Profiling
    # Used to generate the `profile_seq` tag, which effectively counts how many profiles we've attempted to report
    # from a given runtime-id.
    #
    # Note that the above implies a few things:
    # 1. The sequence number only gets incremented when we decide to report a profile and create a `Flush` for it
    # 2. The `SequenceTracker` must live across profiler reconfigurations and resets, since no matter how many
    #    profiler instances get created due to reconfiguration, the runtime-id is still the same, so the sequence number
    #    should be kept and not restarted from 0
    # 3. The `SequenceTracker` must be reset after a fork, since the runtime-id will change, and we want to start
    #    counting from 0 again
    #
    # This is why this module is implemented as a singleton that we reuse, not as an instance that we recreate.
    #
    # Note that this module is not thread-safe, so it's up to the callers to make sure
    # it's only used by a single thread at a time (which is what the `Profiling::Exporter`)
    # is doing.
    module SequenceTracker
      class << self
        include Core::Utils::Forking

        def get_next
          reset! unless defined?(@sequence_number)
          after_fork! { reset! }

          next_seq = @sequence_number
          @sequence_number += 1
          next_seq
        end

        private

        def reset!
          @sequence_number = 0
        end
      end
    end
  end
end
