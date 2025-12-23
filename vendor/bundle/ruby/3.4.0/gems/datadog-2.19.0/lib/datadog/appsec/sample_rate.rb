# frozen_string_literal: true

module Datadog
  module AppSec
    # SampleRate basic sample rate
    class SampleRate
      attr_reader :rate

      def initialize(rate)
        @rate = rate
      end

      def sample?
        return false if rate <= 0
        return true if rate >= 1

        Kernel.rand < rate
      end
    end
  end
end
