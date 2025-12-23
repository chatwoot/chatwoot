# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # A text annotation with a set of attributes and a timestamp for export.
      #
      # Field types are as follows:
      #  name: String
      #  attributes: frozen Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}
      #  timestamp: Integer nanoseconds since Epoch
      Event = Struct.new(:name, :attributes, :timestamp)
    end
  end
end
