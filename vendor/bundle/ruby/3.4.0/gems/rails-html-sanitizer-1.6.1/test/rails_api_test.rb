# frozen_string_literal: true

require "minitest/autorun"
require "rails-html-sanitizer"

class RailsApiTest < Minitest::Test
  def test_html_module_name_alias
    assert_equal(Rails::Html, Rails::HTML)
    assert_equal("Rails::HTML", Rails::Html.name)
    assert_equal("Rails::HTML", Rails::HTML.name)
  end

  def test_html_scrubber_class_names
    assert(Rails::Html::PermitScrubber)
    assert(Rails::Html::TargetScrubber)
    assert(Rails::Html::TextOnlyScrubber)
    assert(Rails::Html::Sanitizer)
  end

  def test_best_supported_vendor_when_html5_is_not_supported_returns_html4
    Rails::HTML::Sanitizer.stub(:html5_support?, false) do
      assert_equal(Rails::HTML4::Sanitizer, Rails::HTML::Sanitizer.best_supported_vendor)
    end
  end

  def test_best_supported_vendor_when_html5_is_supported_returns_html5
    skip("no HTML5 support on this platform") unless Rails::HTML::Sanitizer.html5_support?

    Rails::HTML::Sanitizer.stub(:html5_support?, true) do
      assert_equal(Rails::HTML5::Sanitizer, Rails::HTML::Sanitizer.best_supported_vendor)
    end
  end

  def test_html4_sanitizer_alias_full
    assert_equal(Rails::HTML4::FullSanitizer, Rails::HTML::FullSanitizer)
    assert_equal("Rails::HTML4::FullSanitizer", Rails::HTML::FullSanitizer.name)
  end

  def test_html4_sanitizer_alias_link
    assert_equal(Rails::HTML4::LinkSanitizer, Rails::HTML::LinkSanitizer)
    assert_equal("Rails::HTML4::LinkSanitizer", Rails::HTML::LinkSanitizer.name)
  end

  def test_html4_sanitizer_alias_safe_list
    assert_equal(Rails::HTML4::SafeListSanitizer, Rails::HTML::SafeListSanitizer)
    assert_equal("Rails::HTML4::SafeListSanitizer", Rails::HTML::SafeListSanitizer.name)
  end

  def test_html4_full_sanitizer
    assert_equal(Rails::HTML4::FullSanitizer, Rails::HTML::Sanitizer.full_sanitizer)
    assert_equal(Rails::HTML4::FullSanitizer, Rails::HTML4::Sanitizer.full_sanitizer)
  end

  def test_html4_link_sanitizer
    assert_equal(Rails::HTML4::LinkSanitizer, Rails::HTML::Sanitizer.link_sanitizer)
    assert_equal(Rails::HTML4::LinkSanitizer, Rails::HTML4::Sanitizer.link_sanitizer)
  end

  def test_html4_safe_list_sanitizer
    assert_equal(Rails::HTML4::SafeListSanitizer, Rails::HTML::Sanitizer.safe_list_sanitizer)
    assert_equal(Rails::HTML4::SafeListSanitizer, Rails::HTML4::Sanitizer.safe_list_sanitizer)
  end

  def test_html4_white_list_sanitizer
    assert_equal(Rails::HTML4::SafeListSanitizer, Rails::HTML::Sanitizer.white_list_sanitizer)
    assert_equal(Rails::HTML4::SafeListSanitizer, Rails::HTML4::Sanitizer.white_list_sanitizer)
  end

  def test_html5_full_sanitizer
    skip("no HTML5 support on this platform") unless Rails::HTML::Sanitizer.html5_support?
    assert_equal(Rails::HTML5::FullSanitizer, Rails::HTML5::Sanitizer.full_sanitizer)
  end

  def test_html5_link_sanitizer
    skip("no HTML5 support on this platform") unless Rails::HTML::Sanitizer.html5_support?
    assert_equal(Rails::HTML5::LinkSanitizer, Rails::HTML5::Sanitizer.link_sanitizer)
  end

  def test_html5_safe_list_sanitizer
    skip("no HTML5 support on this platform") unless Rails::HTML::Sanitizer.html5_support?
    assert_equal(Rails::HTML5::SafeListSanitizer, Rails::HTML5::Sanitizer.safe_list_sanitizer)
  end

  def test_html5_white_list_sanitizer
    skip("no HTML5 support on this platform") unless Rails::HTML::Sanitizer.html5_support?
    assert_equal(Rails::HTML5::SafeListSanitizer, Rails::HTML5::Sanitizer.white_list_sanitizer)
  end
end
