# frozen_string_literal: true

require "test_helper"

class DomTestingParserSelectionTest < ActiveSupport::TestCase
  include DomTestingHelpers

  test "with default html4" do
    with_default_html_version(:html4) do
      assert_equal(Nokogiri::HTML4::Document, Rails::Dom::Testing.html_document)
      assert_equal(Nokogiri::HTML4::DocumentFragment, Rails::Dom::Testing.html_document_fragment)

      assert_equal(Nokogiri::HTML4::Document, Rails::Dom::Testing.html_document(html_version: :html4))
      assert_equal(Nokogiri::HTML4::DocumentFragment, Rails::Dom::Testing.html_document_fragment(html_version: :html4))

      if Rails::Dom::Testing.html5_support?
        assert_equal(Nokogiri::HTML5::Document, Rails::Dom::Testing.html_document(html_version: :html5))
        assert_equal(Nokogiri::HTML5::DocumentFragment, Rails::Dom::Testing.html_document_fragment(html_version: :html5))
      else
        assert_raises(NotImplementedError) { Rails::Dom::Testing.html_document(html_version: :html5) }
        assert_raises(NotImplementedError) { Rails::Dom::Testing.html_document_fragment(html_version: :html5) }
      end

      assert_raises(ArgumentError) { Rails::Dom::Testing.html_document(html_version: :html9) }
      assert_raises(ArgumentError) { Rails::Dom::Testing.html_document_fragment(html_version: :html9) }
    end
  end

  test "with default html5" do
    with_default_html_version(:html5) do
      if Rails::Dom::Testing.html5_support?
        assert_equal(Nokogiri::HTML5::Document, Rails::Dom::Testing.html_document)
        assert_equal(Nokogiri::HTML5::DocumentFragment, Rails::Dom::Testing.html_document_fragment)
      else
        assert_raises(NotImplementedError) { Rails::Dom::Testing.html_document }
        assert_raises(NotImplementedError) { Rails::Dom::Testing.html_document_fragment }
      end

      assert_equal(Nokogiri::HTML4::Document, Rails::Dom::Testing.html_document(html_version: :html4))
      assert_equal(Nokogiri::HTML4::DocumentFragment, Rails::Dom::Testing.html_document_fragment(html_version: :html4))

      if Rails::Dom::Testing.html5_support?
        assert_equal(Nokogiri::HTML5::Document, Rails::Dom::Testing.html_document(html_version: :html5))
        assert_equal(Nokogiri::HTML5::DocumentFragment, Rails::Dom::Testing.html_document_fragment(html_version: :html5))
      else
        assert_raises(NotImplementedError) { Rails::Dom::Testing.html_document(html_version: :html5) }
        assert_raises(NotImplementedError) { Rails::Dom::Testing.html_document_fragment(html_version: :html5) }
      end

      assert_raises(ArgumentError) { Rails::Dom::Testing.html_document(html_version: :html9) }
      assert_raises(ArgumentError) { Rails::Dom::Testing.html_document_fragment(html_version: :html9) }
    end
  end

  test "with invalid default" do
    with_default_html_version(:html8) do
      assert_raises(ArgumentError) { Rails::Dom::Testing.html_document }
      assert_raises(ArgumentError) { Rails::Dom::Testing.html_document_fragment }

      assert_equal(Nokogiri::HTML4::Document, Rails::Dom::Testing.html_document(html_version: :html4))
      assert_equal(Nokogiri::HTML4::DocumentFragment, Rails::Dom::Testing.html_document_fragment(html_version: :html4))

      if Rails::Dom::Testing.html5_support?
        assert_equal(Nokogiri::HTML5::Document, Rails::Dom::Testing.html_document(html_version: :html5))
        assert_equal(Nokogiri::HTML5::DocumentFragment, Rails::Dom::Testing.html_document_fragment(html_version: :html5))
      else
        assert_raises(NotImplementedError) { Rails::Dom::Testing.html_document(html_version: :html5) }
        assert_raises(NotImplementedError) { Rails::Dom::Testing.html_document_fragment(html_version: :html5) }
      end

      assert_raises(ArgumentError) { Rails::Dom::Testing.html_document(html_version: :html9) }
      assert_raises(ArgumentError) { Rails::Dom::Testing.html_document_fragment(html_version: :html9) }
    end
  end
end
