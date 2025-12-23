require 'ostruct'
require_relative 'test_helper'
require_relative '../lib/jquery/assert_select'

class AssertSelectJQueryTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions::SelectorAssertions
  attr_reader :response

  JAVASCRIPT_TEST_OUTPUT = <<-JS
    $("#card").show("blind", 1000);
    $("#id").html('<div><p>something</p></div>');
    $('#card').html('<div><p>something else</p></div>');
    jQuery("#id").replaceWith("<div><p>something</p></div>");
    $("<div><p>something</p></div>").appendTo("#id");
    $("<div><p>something else</p></div>").appendTo("#id");
    jQuery("<div><p>something</p></div>").prependTo("#id");
    $('#id').remove();
    jQuery("#id").hide();
    $("[data-placeholder~=name]").remove();
    $("#cart tr:not(.total_line) > *").remove();
    $("[href|=\"val\"][href$=\"val\"][href^=\"val\"]").remove();
    $("tr + td, li").remove();

    // without semicolon
    $("#browser_cart").hide("blind", 1000)

    $('#item').html('<div><span>\\`Total\\`: \\$12.34</span></div>');
  JS

  setup do
    @response = OpenStruct.new(content_type: 'text/javascript', body: JAVASCRIPT_TEST_OUTPUT)
  end

  def test_target_as_receiver
    assert_nothing_raised do
      assert_select_jquery :show, :blind, '#card'
      assert_select_jquery :hide, :blind, '#browser_cart'
      assert_select_jquery :html, '#id' do
        assert_select 'p', 'something'
      end
      assert_select_jquery :replaceWith, '#id' do
        assert_select 'p', 'something'
      end
      assert_select_jquery :remove, "[data-placeholder~=name]"
      assert_select_jquery :remove, "#cart tr:not(.total_line) > *"
      assert_select_jquery :remove, "[href|=\"val\"][href$=\"val\"][href^=\"val\"]"
      assert_select_jquery :remove, "tr + td, li"

      assert_select_jquery :html, '#item' do
        assert_select 'span', '`Total`: $12.34'
      end
    end

    assert_raise Minitest::Assertion, "No JQuery call matches [:show, :some_wrong]" do
      assert_select_jquery :show, :some_wrong
    end

    assert_raise Minitest::Assertion, "<something else> was expected but was <something>" do
      assert_select_jquery :html, '#id' do
        assert_select 'p', 'something else'
      end
    end
  end

  def test_target_as_argument
    assert_nothing_raised do
      assert_select_jquery :appendTo, '#id' do
        assert_select 'p', 'something'
        assert_select 'p', 'something else'
      end
      assert_select_jquery :prependTo, '#id' do
        assert_select 'p', 'something'
      end
    end

    assert_raise Minitest::Assertion, 'No JQuery call matches [:prependTo, "#wrong_id"]' do
      assert_select_jquery :prependTo, '#wrong_id'
    end
  end

  def test_argumentless
    assert_nothing_raised do
      assert_select_jquery :remove
      assert_select_jquery :hide
    end

    assert_raise Minitest::Assertion, 'No JQuery call matches [:wrong_function]' do
      assert_select_jquery :wrong_function
    end
  end
end
