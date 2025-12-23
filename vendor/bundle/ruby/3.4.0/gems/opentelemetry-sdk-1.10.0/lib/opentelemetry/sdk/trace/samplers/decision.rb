# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # The Decision module contains a set of constants to be used in the
        # decision part of a sampling {Result}.
        module Decision
          # Decision to not record events and not sample.
          DROP = :__drop__

          # Decision to record events and not sample.
          RECORD_ONLY = :__record_only__

          # Decision to record events and sample.
          RECORD_AND_SAMPLE = :__record_and_sample__
        end
      end
    end
  end
end
