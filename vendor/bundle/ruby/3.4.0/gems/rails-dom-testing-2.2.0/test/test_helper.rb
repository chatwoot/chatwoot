# frozen_string_literal: true

require "rails-dom-testing"
require "active_support/test_case"
require "minitest/autorun"

ActiveSupport::TestCase.test_order = :random

module DomTestingHelpers
  def jruby?
    !! Nokogiri.jruby?
  end

  def with_default_html_version(version)
    old_version = Rails::Dom::Testing.default_html_version
    begin
      Rails::Dom::Testing.default_html_version = version
      yield
    ensure
      Rails::Dom::Testing.default_html_version = old_version
    end
  end
end
