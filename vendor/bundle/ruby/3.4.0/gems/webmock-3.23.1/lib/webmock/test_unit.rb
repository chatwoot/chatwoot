# frozen_string_literal: true

require 'test/unit'
require 'webmock'

WebMock.enable!

module Test
  module Unit
    class TestCase
      include WebMock::API

      teardown
      def teardown_with_webmock
        WebMock.reset!
      end

    end
  end
end

WebMock::AssertionFailure.error_class = Test::Unit::AssertionFailedError
