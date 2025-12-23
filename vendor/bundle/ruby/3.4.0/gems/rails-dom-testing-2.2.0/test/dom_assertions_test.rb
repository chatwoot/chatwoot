# frozen_string_literal: true

require "test_helper"

class DomAssertionsTest < ActiveSupport::TestCase
  Assertion = Minitest::Assertion

  include Rails::Dom::Testing::Assertions::DomAssertions

  def test_responds_to_assert_dom_equal
    assert respond_to?(:assert_dom_equal)
  end

  def test_dom_equal
    html = "<a></a>"
    assert_dom_equal(html, html.dup)
  end

  def test_equal_doms_with_different_order_attributes
    attributes = %{<a b="hello" c="hello"></a>}
    reverse_attributes = %{<a c="hello" b="hello"></a>}
    assert_dom_equal(attributes, reverse_attributes)
  end

  def test_dom_not_equal
    assert_dom_not_equal("<a></a>", "<b></b>")
  end

  def test_unequal_doms_attributes_with_different_order_and_values
    attributes = %{<a b="hello" c="hello"></a>}
    reverse_attributes = %{<a c="hello" b="goodbye"></a>}
    assert_dom_not_equal(attributes, reverse_attributes)
  end

  def test_custom_message_is_used_in_failures
    message = "This is my message."

    e = assert_raises(Assertion) do
      assert_dom_equal("<a></a>", "<b></b>", message)
    end

    assert_equal e.message, message
  end

  def test_unequal_dom_attributes_in_children
    assert_dom_not_equal(
      %{<a><b c="1" /></a>},
      %{<a><b c="2" /></a>}
    )
  end

  def test_dom_equal_with_whitespace_strict
    canonical = %{<a><b>hello</b> world</a>}
    assert_dom_not_equal(canonical, %{<a>\n<b>hello\n </b> world</a>}, strict: true)
    assert_dom_not_equal(canonical, %{<a> \n <b>\n hello</b> world</a>}, strict: true)
    assert_dom_not_equal(canonical, %{<a>\n\t<b>hello</b> world</a>}, strict: true)
    assert_dom_equal(canonical, %{<a><b>hello</b> world</a>}, strict: true)
  end

  def test_dom_equal_with_whitespace
    canonical = %{<a><b>hello</b> world</a>}
    assert_dom_equal(canonical, %{<a>\n<b>hello\n </b> world</a>})
    assert_dom_equal(canonical, %{<a>\n<b>hello </b>\nworld</a>})
    assert_dom_equal(canonical, %{<a> \n <b>\n hello</b> world</a>})
    assert_dom_equal(canonical, %{<a> \n <b> hello </b>world</a>})
    assert_dom_equal(canonical, %{<a> \n <b>hello </b>world\n</a>\n})
    assert_dom_equal(canonical, %{<a>\n\t<b>hello</b> world</a>})
    assert_dom_equal(canonical, %{<a>\n\t<b>hello </b>\n\tworld</a>})
  end

  def test_dom_equal_with_attribute_whitespace
    canonical = %(<div data-wow="Don't strip this">)
    assert_dom_equal(canonical, %(<div data-wow="Don't strip this">))
    assert_dom_not_equal(canonical, %(<div data-wow="Don't  strip this">))
  end

  def test_dom_equal_with_indentation
    canonical = %{<a>hello <b>cruel</b> world</a>}
    assert_dom_equal(canonical, <<-HTML)
<a>
  hello
  <b>cruel</b>
  world
</a>
    HTML

    assert_dom_equal(canonical, <<-HTML)
<a>
hello
<b>cruel</b>
world
</a>
    HTML

    assert_dom_equal(canonical, <<-HTML)
<a>hello
  <b>
    cruel
  </b>
  world</a>
    HTML
  end

  def test_dom_equal_with_surrounding_whitespace
    canonical = %{<p>Lorem ipsum dolor</p><p>sit amet, consectetur adipiscing elit</p>}
    assert_dom_equal(canonical, <<-HTML)
<p>
  Lorem
  ipsum
  dolor
</p>

<p>
  sit amet,
  consectetur
  adipiscing elit
</p>
    HTML
  end

  def test_dom_not_equal_with_interior_whitespace
    with_space    = %{<a><b>hello world</b></a>}
    without_space = %{<a><b>helloworld</b></a>}
    assert_dom_not_equal(with_space, without_space)
  end
end

class DomAssertionsHtmlParserSelectionTest < ActiveSupport::TestCase
  include DomTestingHelpers
  include Rails::Dom::Testing::Assertions::DomAssertions

  def setup
    super

    # https://html.spec.whatwg.org/multipage/parsing.html#an-introduction-to-error-handling-and-strange-cases-in-the-parser
    # we use these results to assert that we're invoking the expected parser.
    @input = "<p>1<b>2<i>3</b>4</i>5</p>"
    @html4_result = jruby? ? "<p>1<b>2<i>3</i></b><i>4</i>5</p>" : "<p>1<b>2<i>3</i></b>45</p>"
    @html5_result = jruby? ? nil                                 : "<p>1<b>2<i>3</i></b><i>4</i>5</p>"
  end

  test "default value is html4" do
    assert_equal(:html4, Rails::Dom::Testing.default_html_version)
  end

  test "default html4, no version specified" do
    with_default_html_version(:html4) do
      assert_dom_equal(@html4_result, @input)
      assert_dom_not_equal(@html5_result, @input)
    end
  end

  test "default html4, html4 specified" do
    with_default_html_version(:html4) do
      assert_dom_equal(@html4_result, @input, html_version: :html4)
      assert_dom_not_equal(@html5_result, @input, html_version: :html4)
    end
  end

  test "default html4, html5 specified" do
    skip("html5 is not supported") unless Rails::Dom::Testing.html5_support?

    with_default_html_version(:html4) do
      assert_dom_equal(@html5_result, @input, html_version: :html5)
      assert_dom_not_equal(@html4_result, @input, html_version: :html5)
    end
  end

  test "default html5, no version specified" do
    skip("html5 is not supported") unless Rails::Dom::Testing.html5_support?

    with_default_html_version(:html5) do
      assert_dom_equal(@html5_result, @input)
      assert_dom_not_equal(@html4_result, @input)
    end
  end

  test "default html5, html4 specified" do
    with_default_html_version(:html5) do
      assert_dom_equal(@html4_result, @input, html_version: :html4)
      assert_dom_not_equal(@html5_result, @input, html_version: :html4)
    end
  end

  test "default html5, html5 specified" do
    skip("html5 is not supported") unless Rails::Dom::Testing.html5_support?

    with_default_html_version(:html5) do
      assert_dom_equal(@html5_result, @input, html_version: :html5)
      assert_dom_not_equal(@html4_result, @input, html_version: :html5)
    end
  end

  test "raise NotImplementedError html5 when not supported" do
    Rails::Dom::Testing.stub(:html5_support?, false) do
      with_default_html_version(:html5) do
        assert_raises(NotImplementedError) { assert_dom_equal("a", "b") }
        assert_raises(NotImplementedError) { assert_dom_equal("a", "b", html_version: :html5) }
        assert_nothing_raised { assert_dom_equal(@html4_result, @input, html_version: :html4) }
      end
    end
  end

  test "default set to invalid" do
    with_default_html_version(:html9) do
      assert_raises(ArgumentError) { assert_dom_equal("a", "b") }
    end
  end

  test "invalid version specified" do
    assert_raises(ArgumentError) { assert_dom_equal("a", "b", html_version: :html9) }
  end
end
