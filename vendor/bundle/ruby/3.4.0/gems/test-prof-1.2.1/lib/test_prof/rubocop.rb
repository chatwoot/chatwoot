# frozen_string_literal: true

require "test_prof/utils"
supported = TestProf::Utils.verify_gem_version("rubocop", at_least: "0.51.0")
unless supported
  warn "TestProf cops require RuboCop >= 0.51.0 to run."
  return
end

require "rubocop"

require "test_prof/cops/inject"
require "test_prof/cops/rspec/aggregate_examples"
