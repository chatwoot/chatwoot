# frozen_string_literal: true

require 'webmock'
require 'webmock/rspec/matchers/request_pattern_matcher'
require 'webmock/rspec/matchers/webmock_matcher'

module WebMock
  module Matchers
    def have_been_made
      WebMock::RequestPatternMatcher.new
    end

    def have_been_requested
      WebMock::RequestPatternMatcher.new
    end

    def have_not_been_made
      WebMock::RequestPatternMatcher.new.times(0)
    end

    def have_requested(method, uri)
      WebMock::WebMockMatcher.new(method, uri)
    end

    def have_not_requested(method, uri)
      WebMock::WebMockMatcher.new(method, uri).times(0)
    end
  end
end
