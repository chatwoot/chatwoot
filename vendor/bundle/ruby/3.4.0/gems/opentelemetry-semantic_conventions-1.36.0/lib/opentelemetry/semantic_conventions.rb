# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # OpenTelemetry semantic convention attribute names as constants.
  # These are auto-generated from source YAML in {https://github.com/open-telemetry/semantic-conventions the semantic-conventions repository}.
  #
  # Except for the {Resource} and {Trace} modules, constants in this namespace have been declared stable by the OpenTelemetry semantic conventions working group.
  #
  # @note The constants here ought to remain within major versions of this library.
  #   However, there risk with auto-generated code.
  #   The maintainers try to prevent constants disappearing, but we cannot gaurantee this.
  #   We strongly recommend that any constants you use in your code are exercised in your test suite to catch missing constants before release or production runtime.
  module SemanticConventions
  end
end

# TODO: test to make sure the trace and resource constants are present in SemConv::Incubating
# TODO: test to make sure the SemConv (stable) constants are all still present in the SemConv::Incubating constants
# TODO: remove these convenience requires in the next major version
require_relative 'semantic_conventions/trace'
require_relative 'semantic_conventions/resource'
# TODO: we're not going to add any more convenience requires here; require directly what you use
