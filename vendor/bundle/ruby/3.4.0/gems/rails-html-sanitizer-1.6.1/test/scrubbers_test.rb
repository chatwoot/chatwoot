# frozen_string_literal: true

require "minitest/autorun"
require "rails-html-sanitizer"

class ScrubberTest < Minitest::Test
  protected
    def scrub_fragment(html)
      Loofah.scrub_fragment(html, @scrubber).to_s
    end

    def assert_scrubbed(html, expected = html)
      output = scrub_fragment(html)
      assert_equal expected, output
    end

    def to_node(text)
      Loofah.fragment(text).children.first
    end

    def assert_node_skipped(text)
      assert_scrub_returns(Loofah::Scrubber::CONTINUE, text)
    end

    def assert_scrub_stopped(text)
      assert_scrub_returns(Loofah::Scrubber::STOP, text)
    end

    def assert_scrub_returns(return_value, text)
      node = to_node(text)
      assert_equal return_value, @scrubber.scrub(node)
    end
end

class PermitScrubberTest < ScrubberTest
  def setup
    @scrubber = Rails::HTML::PermitScrubber.new
  end

  def test_responds_to_scrub
    assert @scrubber.respond_to?(:scrub)
  end

  def test_default_scrub_behavior
    assert_scrubbed "<tag>hello</tag>", "hello"
  end

  def test_default_scrub_removes_comments
    assert_scrubbed("<div>one</div><!-- two --><span>three</span>",
                    "<div>one</div><span>three</span>")
  end

  def test_default_scrub_removes_processing_instructions
    input = "<div>one</div><?div two><span>three</span>"
    result = scrub_fragment(input)

    acceptable_results = [
      # jruby cyberneko (nokogiri < 1.14.0)
      "<div>one</div>",
      # everything else
      "<div>one</div><span>three</span>",
    ]

    assert_includes(acceptable_results, result)
  end

  def test_default_attributes_removal_behavior
    assert_scrubbed '<p cooler="hello">hello</p>', "<p>hello</p>"
  end

  def test_leaves_supplied_tags
    @scrubber.tags = %w(a)
    assert_scrubbed "<a>hello</a>"
  end

  def test_leaves_only_supplied_tags
    html = "<tag>leave me <span>now</span></tag>"
    @scrubber.tags = %w(tag)
    assert_scrubbed html, "<tag>leave me now</tag>"
  end

  def test_prunes_tags
    @scrubber = Rails::HTML::PermitScrubber.new(prune: true)
    @scrubber.tags = %w(tag)
    html = "<tag>leave me <span>now</span></tag>"
    assert_scrubbed html, "<tag>leave me </tag>"
  end

  def test_leaves_comments_when_supplied_as_tag
    @scrubber.tags = %w(div comment)
    assert_scrubbed("<div>one</div><!-- two --><span>three</span>",
                    "<div>one</div><!-- two -->three")
  end

  def test_leaves_only_supplied_tags_nested
    html = "<tag>leave <em>me <span>now</span></em></tag>"
    @scrubber.tags = %w(tag)
    assert_scrubbed html, "<tag>leave me now</tag>"
  end

  def test_leaves_supplied_attributes
    @scrubber.attributes = %w(cooler)
    assert_scrubbed '<a cooler="hello"></a>'
  end

  def test_leaves_only_supplied_attributes
    @scrubber.attributes = %w(cooler)
    assert_scrubbed '<a cooler="hello" b="c" d="e"></a>', '<a cooler="hello"></a>'
  end

  def test_leaves_supplied_tags_and_attributes
    @scrubber.tags = %w(tag)
    @scrubber.attributes = %w(cooler)
    assert_scrubbed '<tag cooler="hello"></tag>'
  end

  def test_leaves_only_supplied_tags_and_attributes
    @scrubber.tags = %w(tag)
    @scrubber.attributes = %w(cooler)
    html = '<a></a><tag href=""></tag><tag cooler=""></tag>'
    assert_scrubbed html, '<tag></tag><tag cooler=""></tag>'
  end

  def test_does_not_allow_safelisted_mglyph
    # https://hackerone.com/reports/2519936
    assert_output(nil, /WARNING: 'mglyph' tags cannot be allowed by the PermitScrubber/) do
      @scrubber.tags = ["div", "mglyph", "span"]
    end
    assert_equal(["div", "span"], @scrubber.tags)
  end

  def test_does_not_allow_safelisted_malignmark
    # https://hackerone.com/reports/2519936
    assert_output(nil, /WARNING: 'malignmark' tags cannot be allowed by the PermitScrubber/) do
      @scrubber.tags = ["div", "malignmark", "span"]
    end
    assert_equal(["div", "span"], @scrubber.tags)
  end

  def test_does_not_allow_safelisted_noscript
    # https://hackerone.com/reports/2509647
    assert_output(nil, /WARNING: 'noscript' tags cannot be allowed by the PermitScrubber/) do
      @scrubber.tags = ["div", "noscript", "span"]
    end
    assert_equal(["div", "span"], @scrubber.tags)
  end

  def test_leaves_text
    assert_scrubbed("some text")
  end

  def test_skips_text_nodes
    assert_node_skipped("some text")
  end

  def test_tags_accessor_validation
    e = assert_raises(ArgumentError) do
      @scrubber.tags = "tag"
    end

    assert_equal "You should pass :tags as an Enumerable", e.message
    assert_nil @scrubber.tags, "Tags should be nil when validation fails"
  end

  def test_attributes_accessor_validation
    e = assert_raises(ArgumentError) do
      @scrubber.attributes = "cooler"
    end

    assert_equal "You should pass :attributes as an Enumerable", e.message
    assert_nil @scrubber.attributes, "Attributes should be nil when validation fails"
  end
end

class TargetScrubberTest < ScrubberTest
  def setup
    @scrubber = Rails::HTML::TargetScrubber.new
  end

  def test_targeting_tags_removes_only_them
    @scrubber.tags = %w(a h1)
    html = "<script></script><a></a><h1></h1>"
    assert_scrubbed html, "<script></script>"
  end

  def test_targeting_tags_removes_only_them_nested
    @scrubber.tags = %w(a)
    html = "<tag><a><tag><a></a></tag></a></tag>"
    assert_scrubbed html, "<tag><tag></tag></tag>"
  end

  def test_targeting_attributes_removes_only_them
    @scrubber.attributes = %w(class id)
    html = '<a class="a" id="b" onclick="c"></a>'
    assert_scrubbed html, '<a onclick="c"></a>'
  end

  def test_targeting_tags_and_attributes_removes_only_them
    @scrubber.tags = %w(tag)
    @scrubber.attributes = %w(remove)
    html = '<tag remove="" other=""></tag><a remove="" other=""></a>'
    assert_scrubbed html, '<a other=""></a>'
  end

  def test_prunes_tags
    @scrubber = Rails::HTML::TargetScrubber.new(prune: true)
    @scrubber.tags = %w(span)
    html = "<tag>leave me <span>now</span></tag>"
    assert_scrubbed html, "<tag>leave me </tag>"
  end
end

class TextOnlyScrubberTest < ScrubberTest
  def setup
    @scrubber = Rails::HTML::TextOnlyScrubber.new
  end

  def test_removes_all_tags_and_keep_the_content
    assert_scrubbed "<tag>hello</tag>", "hello"
  end

  def test_skips_text_nodes
    assert_node_skipped("some text")
  end
end

class ReturningStopFromScrubNodeTest < ScrubberTest
  class ScrubStopper < Rails::HTML::PermitScrubber
    def scrub_node(node)
      Loofah::Scrubber::STOP
    end
  end

  class ScrubContinuer < Rails::HTML::PermitScrubber
    def scrub_node(node)
      Loofah::Scrubber::CONTINUE
    end
  end

  def test_returns_stop_from_scrub_if_scrub_node_does
    @scrubber = ScrubStopper.new
    assert_scrub_stopped "<script>remove me</script>"
  end

  def test_returns_continue_from_scrub_if_scrub_node_does
    @scrubber = ScrubContinuer.new
    assert_node_skipped "<script>keep me</script>"
  end
end

class PermitScrubberMinimalOperationsTest < ScrubberTest
  class TestPermitScrubber < Rails::HTML::PermitScrubber
    def initialize
      @scrub_attribute_args = []
      @scrub_attributes_args = []

      super

      self.tags = ["div"]
      self.attributes = ["class"]
    end

    def scrub_attributes(node)
      @scrub_attributes_args << node.name

      super
    end

    def scrub_attribute(node, attr)
      @scrub_attribute_args << [node.name, attr.name]

      super
    end
  end

  def test_does_not_scrub_removed_attributes
    @scrubber = TestPermitScrubber.new

    input = "<div class='foo' href='bar'></div>"
    frag = scrub_fragment(input)
    assert_equal("<div class=\"foo\"></div>", frag)

    assert_equal([["div", "class"]], @scrubber.instance_variable_get(:@scrub_attribute_args))
  end

  def test_does_not_scrub_attributes_of_a_removed_node
    @scrubber = TestPermitScrubber.new

    input = "<div class='foo' href='bar'><svg xlink:href='asdf'><set></set></svg></div>"
    frag = scrub_fragment(input)
    assert_equal("<div class=\"foo\"></div>", frag)

    assert_equal(["div"], @scrubber.instance_variable_get(:@scrub_attributes_args))
  end
end
