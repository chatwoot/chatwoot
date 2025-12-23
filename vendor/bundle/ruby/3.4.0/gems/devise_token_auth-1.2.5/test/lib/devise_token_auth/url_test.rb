# frozen_string_literal: true

require 'test_helper'

class DeviseTokenAuth::UrlTest < ActiveSupport::TestCase
  describe 'DeviseTokenAuth::Url#generate' do
    test 'URI fragment should appear at the end of URL with repeat of query params' do
      params = { client_id: 123 }
      url = 'http://example.com#fragment'
      assert_equal DeviseTokenAuth::Url.send(:generate, url, params), 'http://example.com?client_id=123#fragment?client_id=123'
    end

    describe 'with existing query params' do
      test 'should preserve existing query params' do
        url = 'http://example.com?a=1'
        assert_equal DeviseTokenAuth::Url.send(:generate, url), 'http://example.com?a=1'
      end

      test 'should marge existing query params with new ones' do
        params = { client_id: 123 }
        url = 'http://example.com?a=1'
        assert_equal DeviseTokenAuth::Url.send(:generate, url, params), 'http://example.com?a=1&client_id=123'
      end
    end
  end
end
