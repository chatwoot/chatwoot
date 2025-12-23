# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
require_relative './instrumentation/registry'

module OpenTelemetry
  # Instrumentation should be able to handle the case when the library is not installed on a user's system.
  module Instrumentation
    extend self
    # @return [Registry] registry containing all known
    #  instrumentation
    def registry
      @registry ||= Registry.new
    end
  end
end
