# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # InstrumentationLibrary is a struct containing library information for export.
    # @deprecated Use InstrumentationScope instead.
    InstrumentationLibrary = Struct.new(:name,
                                        :version)
  end
end
