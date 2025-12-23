# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # InstrumentationScope is a struct containing scope information for export.
    InstrumentationScope = Struct.new(:name,
                                      :version)
  end
end
