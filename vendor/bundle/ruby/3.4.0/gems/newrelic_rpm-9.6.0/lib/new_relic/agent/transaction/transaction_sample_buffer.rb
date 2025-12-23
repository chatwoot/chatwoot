# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class Transaction
      class TransactionSampleBuffer
        attr_reader :samples

        SINGLE_BUFFER_MAX = 20

        def initialize
          @samples = []
        end

        def enabled?
          true
        end

        def reset!
          @samples = []
        end

        def harvest_samples
          @samples
        ensure
          reset!
        end

        def allow_sample?(sample)
          true
        end

        def store(sample)
          return unless enabled?

          if allow_sample?(sample)
            add_sample(sample)
            truncate_samples_if_needed
          end
        end

        def store_previous(previous_samples)
          return unless enabled?

          previous_samples.each do |sample|
            add_sample(sample) if allow_sample?(sample)
          end
          truncate_samples_if_needed
        end

        def truncate_samples_if_needed
          truncate_samples if full?
        end

        def full?
          @samples.length >= max_capacity
        end

        # Capacity is the desired number of samples a buffer will hold. This
        # can be user dictated via config if a feature wants.
        #
        # This value will be forcibly capped by the max_capacity
        def capacity
          raise NotImplementedError.new('TransactionSampleBuffer subclasses must provide a capacity override')
        end

        # Apply hard upper limit to the capacity to prevent users from
        # consuming too much memory buffering TT's.
        #
        # A typical buffer should NOT override this method (although we do for
        # odd things like dev-mode)
        def max_capacity
          [capacity, SINGLE_BUFFER_MAX].min
        end

        # Our default truncation strategy is to keep max_capacity
        # worth of the longest samples. Override this method for alternate
        # behavior.
        #
        # This doesn't use the more convenient #last and #sort_by to avoid
        # additional array allocations (and abundant alliteration)
        def truncate_samples
          @samples.sort! { |a, b| a.duration <=> b.duration }
          @samples.slice!(0..-(max_capacity + 1))
        end

        # When pushing a scope different sample buffers potentially want to
        # know about what's happening to annotate the incoming nodes
        def visit_node(*)
          # no-op
        end

        private

        # If a buffer needs to modify an added sample, override this method.
        # Bounds checking, allowing samples and truncation belongs elsewhere.
        def add_sample(sample)
          @samples << sample
        end
      end
    end
  end
end
