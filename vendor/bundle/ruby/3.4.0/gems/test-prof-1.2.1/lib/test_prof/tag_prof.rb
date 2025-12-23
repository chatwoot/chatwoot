# frozen_string_literal: true

require "test_prof/tag_prof/result"
require "test_prof/tag_prof/printers/simple"
require "test_prof/tag_prof/printers/html"

module TestProf
  module TagProf # :nodoc:
  end
end

require "test_prof/tag_prof/rspec" if TestProf.rspec?
