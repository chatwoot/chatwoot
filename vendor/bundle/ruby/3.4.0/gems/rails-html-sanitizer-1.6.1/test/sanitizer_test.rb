# frozen_string_literal: true

require "minitest/autorun"
require "rails-html-sanitizer"

puts "nokogiri version info: #{Nokogiri::VERSION_INFO}"
puts "html5 support: #{Rails::HTML::Sanitizer.html5_support?}"

#
#  NOTE that many of these tests contain multiple acceptable results.
#
#  In some cases, this is because of how the HTML4 parser's recovery behavior changed in libxml2
#  2.9.14 and 2.10.0. For more details, see:
#
#  - https://github.com/sparklemotion/nokogiri/releases/tag/v1.13.5
#  - https://gitlab.gnome.org/GNOME/libxml2/-/issues/380
#
#  In other cases, multiple acceptable results are provided because Nokogiri's vendored libxml2 is
#  patched to entity-escape server-side includes (aks "SSI", aka `<!-- #directive param=value -->`).
#
#  In many other cases, it's because the parser used by Nokogiri on JRuby (xerces+nekohtml) parses
#  slightly differently than libxml2 in edge cases.
#
module SanitizerTests
  def self.loofah_html5_support?
    Loofah.respond_to?(:html5_support?) && Loofah.html5_support?
  end

  class BaseSanitizerTest < Minitest::Test
    class XpathRemovalTestSanitizer < Rails::HTML::Sanitizer
      def sanitize(html, options = {})
        fragment = Loofah.fragment(html)
        remove_xpaths(fragment, options[:xpaths]).to_s
      end
    end

    def test_sanitizer_sanitize_raises_not_implemented_error
      assert_raises NotImplementedError do
        Rails::HTML::Sanitizer.new.sanitize("asdf")
      end
    end

    def test_remove_xpaths_removes_an_xpath
      html = %(<h1>hello <script>code!</script></h1>)
      assert_equal %(<h1>hello </h1>), xpath_sanitize(html, xpaths: %w(.//script))
    end

    def test_remove_xpaths_removes_all_occurrences_of_xpath
      html = %(<section><header><script>code!</script></header><p>hello <script>code!</script></p></section>)
      assert_equal %(<section><header></header><p>hello </p></section>), xpath_sanitize(html, xpaths: %w(.//script))
    end

    def test_remove_xpaths_called_with_faulty_xpath
      assert_raises Nokogiri::XML::XPath::SyntaxError do
        xpath_sanitize("<h1>hello<h1>", xpaths: %w(..faulty_xpath))
      end
    end

    def test_remove_xpaths_called_with_xpath_string
      assert_equal "", xpath_sanitize("<a></a>", xpaths: ".//a")
    end

    def test_remove_xpaths_called_with_enumerable_xpaths
      assert_equal "", xpath_sanitize("<a><span></span></a>", xpaths: %w(.//a .//span))
    end

    protected
      def xpath_sanitize(input, options = {})
        XpathRemovalTestSanitizer.new.sanitize(input, options)
      end
  end

  module ModuleUnderTest
    def module_under_test
      self.class.instance_variable_get(:@module_under_test)
    end
  end

  module FullSanitizerTest
    include ModuleUnderTest

    def test_strip_tags_with_quote
      input = '<" <img src="trollface.gif" onload="alert(1)"> hi'
      result = full_sanitize(input)
      acceptable_results = [
        # libxml2 >= 2.9.14 and xerces+neko
        %{&lt;"  hi},
        # other libxml2
        %{ hi},
      ]

      assert_includes(acceptable_results, result)
    end

    def test_strip_invalid_html
      assert_equal "&lt;&lt;", full_sanitize("<<<bad html")
    end

    def test_strip_nested_tags
      expected = "Wei&lt;a onclick='alert(document.cookie);'/&gt;rdos"
      input = "Wei<<a>a onclick='alert(document.cookie);'</a>/>rdos"
      assert_equal expected, full_sanitize(input)
    end

    def test_strip_tags_multiline
      expected = %{This is a test.\n\n\n\nIt no longer contains any HTML.\n}
      input = %{<h1>This is <b>a <a href="" target="_blank">test</a></b>.</h1>\n\n<!-- it has a comment -->\n\n<p>It no <b>longer <strong>contains <em>any <strike>HTML</strike></em>.</strong></b></p>\n}

      assert_equal expected, full_sanitize(input)
    end

    def test_remove_unclosed_tags
      input = "This is <-- not\n a comment here."
      result = full_sanitize(input)
      acceptable_results = [
        # libxml2 >= 2.9.14 and xerces+neko
        %{This is &lt;-- not\n a comment here.},
        # other libxml2
        %{This is },
      ]

      assert_includes(acceptable_results, result)
    end

    def test_strip_cdata
      input = "This has a <![CDATA[<section>]]> here."
      result = full_sanitize(input)
      acceptable_results = [
        # libxml2 = 2.9.14
        %{This has a &lt;![CDATA[]]&gt; here.},
        # other libxml2
        %{This has a ]]&gt; here.},
        # xerces+neko
        %{This has a  here.},
      ]

      assert_includes(acceptable_results, result)
    end

    def test_strip_blank_string
      assert_nil full_sanitize(nil)
      assert_equal "", full_sanitize("")
      assert_equal "   ", full_sanitize("   ")
    end

    def test_strip_tags_with_plaintext
      assert_equal "Don't touch me", full_sanitize("Don't touch me")
    end

    def test_strip_tags_with_tags
      assert_equal "This is a test.", full_sanitize("<p>This <u>is<u> a <a href='test.html'><strong>test</strong></a>.</p>")
    end

    def test_escape_tags_with_many_open_quotes
      assert_equal "&lt;&lt;", full_sanitize("<<<bad html>")
    end

    def test_strip_tags_with_sentence
      assert_equal "This is a test.", full_sanitize("This is a test.")
    end

    def test_strip_tags_with_comment
      assert_equal "This has a  here.", full_sanitize("This has a <!-- comment --> here.")
    end

    def test_strip_tags_with_frozen_string
      assert_equal "Frozen string with no tags", full_sanitize("Frozen string with no tags")
    end

    def test_full_sanitize_respect_html_escaping_of_the_given_string
      assert_equal 'test\r\nstring', full_sanitize('test\r\nstring')
      assert_equal "&amp;", full_sanitize("&")
      assert_equal "&amp;", full_sanitize("&amp;")
      assert_equal "&amp;amp;", full_sanitize("&amp;amp;")
      assert_equal "omg &lt;script&gt;BOM&lt;/script&gt;", full_sanitize("omg &lt;script&gt;BOM&lt;/script&gt;")
    end

    def test_sanitize_ascii_8bit_string
      full_sanitize("<div><a>hello</a></div>".encode("ASCII-8BIT")).tap do |sanitized|
        assert_equal "hello", sanitized
        assert_equal Encoding::UTF_8, sanitized.encoding
      end
    end

    protected
      def full_sanitize(input, options = {})
        module_under_test::FullSanitizer.new.sanitize(input, options)
      end
  end

  class HTML4FullSanitizerTest < Minitest::Test
    @module_under_test = Rails::HTML4
    include FullSanitizerTest
  end

  class HTML5FullSanitizerTest < Minitest::Test
    @module_under_test = Rails::HTML5
    include FullSanitizerTest
  end if loofah_html5_support?

  module LinkSanitizerTest
    include ModuleUnderTest

    def test_strip_links_with_tags_in_tags
      expected = "&lt;a href='hello'&gt;all <b>day</b> long&lt;/a&gt;"
      input = "<<a>a href='hello'>all <b>day</b> long<</A>/a>"
      assert_equal expected, link_sanitize(input)
    end

    def test_strip_links_with_unclosed_tags
      assert_equal "", link_sanitize("<a<a")
    end

    def test_strip_links_with_plaintext
      assert_equal "Don't touch me", link_sanitize("Don't touch me")
    end

    def test_strip_links_with_line_feed_and_uppercase_tag
      assert_equal "on my mind\nall day long", link_sanitize("<a href='almost'>on my mind</a>\n<A href='almost'>all day long</A>")
    end

    def test_strip_links_leaves_nonlink_tags
      assert_equal "My mind\nall <b>day</b> long", link_sanitize("<a href='almost'>My mind</a>\n<A href='almost'>all <b>day</b> long</A>")
    end

    def test_strip_links_with_links
      assert_equal "0wn3d", link_sanitize("<a href='http://www.rubyonrails.com/'><a href='http://www.rubyonrails.com/' onlclick='steal()'>0wn3d</a></a>")
    end

    def test_strip_links_with_linkception
      assert_equal "Magic", link_sanitize("<a href='http://www.rubyonrails.com/'>Mag<a href='http://www.ruby-lang.org/'>ic")
    end

    def test_sanitize_ascii_8bit_string
      link_sanitize("<div><a>hello</a></div>".encode("ASCII-8BIT")).tap do |sanitized|
        assert_equal "<div>hello</div>", sanitized
        assert_equal Encoding::UTF_8, sanitized.encoding
      end
    end

    protected
      def link_sanitize(input, options = {})
        module_under_test::LinkSanitizer.new.sanitize(input, options)
      end
  end

  class HTML4LinkSanitizerTest < Minitest::Test
    @module_under_test = Rails::HTML4
    include LinkSanitizerTest
  end

  class HTML5LinkSanitizerTest < Minitest::Test
    @module_under_test = Rails::HTML5
    include LinkSanitizerTest
  end if loofah_html5_support?

  module SafeListSanitizerTest
    include ModuleUnderTest

    def test_sanitize_nested_script
      assert_equal '&lt;script&gt;alert("XSS");&lt;/script&gt;', safe_list_sanitize('<script><script></script>alert("XSS");<script><</script>/</script><script>script></script>', tags: %w(em))
    end

    def test_sanitize_nested_script_in_style
      input = '<style><script></style>alert("XSS");<style><</style>/</style><style>script></style>'
      result = safe_list_sanitize(input, tags: %w(em))
      acceptable_results = [
        # libxml2
        %{&lt;script&gt;alert("XSS");&lt;/script&gt;},
        # xerces+neko. unavoidable double-escaping, see loofah/docs/2022-10-decision-on-cdata-nodes.md
        %{&amp;lt;script&amp;gt;alert(\"XSS\");&amp;lt;&amp;lt;/style&amp;gt;/script&amp;gt;},
      ]

      assert_includes(acceptable_results, result)
    end

    def test_strip_unclosed_cdata
      input = "This has an unclosed <![CDATA[<section>]] here..."

      result = safe_list_sanitize(input)

      acceptable_results = [
        # libxml2 = 2.9.14
        %{This has an unclosed &lt;![CDATA[]] here...},
        # other libxml2
        %{This has an unclosed ]] here...},
        # xerces+neko
        %{This has an unclosed }
      ]

      assert_includes(acceptable_results, result)
    end

    def test_sanitize_form
      assert_sanitized "<form action=\"/foo/bar\" method=\"post\"><input></form>", ""
    end

    def test_sanitize_plaintext
      # note that the `plaintext` tag has been deprecated since HTML 2
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/plaintext
      input = "<plaintext><span>foo</span></plaintext>"
      result = safe_list_sanitize(input)
      acceptable_results = [
        # libxml2
        "<span>foo</span>",
        # xerces+nekohtml-unit
        "&lt;span&gt;foo&lt;/span&gt;&lt;/plaintext&gt;",
        # xerces+cyberneko
        "&lt;span&gt;foo&lt;/span&gt;"
      ]

      assert_includes(acceptable_results, result)
    end

    def test_sanitize_script
      assert_sanitized "a b c<script language=\"Javascript\">blah blah blah</script>d e f", "a b cblah blah blahd e f"
    end

    def test_sanitize_js_handlers
      raw = %{onthis="do that" <a href="#" onclick="hello" name="foo" onbogus="remove me">hello</a>}
      assert_sanitized raw, %{onthis="do that" <a href="#" name="foo">hello</a>}
    end

    def test_sanitize_javascript_href
      raw = %{href="javascript:bang" <a href="javascript:bang" name="hello">foo</a>, <span href="javascript:bang">bar</span>}
      assert_sanitized raw, %{href="javascript:bang" <a name="hello">foo</a>, <span>bar</span>}
    end

    def test_sanitize_image_src
      raw = %{src="javascript:bang" <img src="javascript:bang" width="5">foo</img>, <span src="javascript:bang">bar</span>}
      assert_sanitized raw, %{src="javascript:bang" <img width="5">foo, <span>bar</span>}
    end

    def test_should_allow_anchors
      assert_sanitized %(<a href="foo" onclick="bar"><script>baz</script></a>), %(<a href=\"foo\">baz</a>)
    end

    def test_video_poster_sanitization
      scope_allowed_tags(%w(video)) do
        scope_allowed_attributes %w(src poster) do
          expected = if RUBY_PLATFORM == "java"
            # xerces+nekohtml alphabetizes the attributes! FML.
            %(<video poster="posterimage.jpg" src="videofile.ogg"></video>)
          else
            %(<video src="videofile.ogg" poster="posterimage.jpg"></video>)
          end
          assert_sanitized(
            %(<video src="videofile.ogg" autoplay  poster="posterimage.jpg"></video>),
            expected,
          )
          assert_sanitized(
            %(<video src="videofile.ogg" poster=javascript:alert(1)></video>),
            %(<video src="videofile.ogg"></video>),
          )
        end
      end
    end

    # RFC 3986, sec 4.2
    def test_allow_colons_in_path_component
      assert_sanitized "<a href=\"./this:that\">foo</a>"
    end

    %w(src width height alt).each do |img_attr|
      define_method "test_should_allow_image_#{img_attr}_attribute" do
        assert_sanitized %(<img #{img_attr}="foo" onclick="bar" />), %(<img #{img_attr}="foo">)
      end
    end

    def test_lang_and_xml_lang
      # https://html.spec.whatwg.org/multipage/dom.html#the-lang-and-xml:lang-attributes
      #
      # 3.2.6.2 The lang and xml:lang attributes
      #
      # ... Authors must not use the lang attribute in the XML namespace on HTML elements in HTML
      # documents. To ease migration to and from XML, authors may specify an attribute in no namespace
      # with no prefix and with the literal localname "xml:lang" on HTML elements in HTML documents,
      # but such attributes must only be specified if a lang attribute in no namespace is also
      # specified, and both attributes must have the same value when compared in an ASCII
      # case-insensitive manner.
      input = expected = "<div lang=\"en\" xml:lang=\"en\">foo</div>"
      assert_sanitized(input, expected)
    end

    def test_should_handle_non_html
      assert_sanitized "abc"
    end

    def test_should_handle_blank_text
      assert_nil(safe_list_sanitize(nil))
      assert_equal("", safe_list_sanitize(""))
      assert_equal("   ", safe_list_sanitize("   "))
    end

    def test_setting_allowed_tags_affects_sanitization
      scope_allowed_tags %w(u) do |sanitizer|
        assert_equal "<u></u>", sanitizer.sanitize("<a><u></u></a>")
      end
    end

    def test_setting_allowed_attributes_affects_sanitization
      scope_allowed_attributes %w(foo) do |sanitizer|
        input = '<a foo="hello" bar="world"></a>'
        assert_equal '<a foo="hello"></a>', sanitizer.sanitize(input)
      end
    end

    def test_custom_tags_overrides_allowed_tags
      scope_allowed_tags %(u) do |sanitizer|
        input = "<a><u></u></a>"
        assert_equal "<a></a>", sanitizer.sanitize(input, tags: %w(a))
      end
    end

    def test_custom_attributes_overrides_allowed_attributes
      scope_allowed_attributes %(foo) do |sanitizer|
        input = '<a foo="hello" bar="world"></a>'
        assert_equal '<a bar="world"></a>', sanitizer.sanitize(input, attributes: %w(bar))
      end
    end

    def test_should_allow_prune
      sanitizer = module_under_test::SafeListSanitizer.new(prune: true)
      text = "<u>leave me <b>now</b></u>"
      assert_equal "<u>leave me </u>", sanitizer.sanitize(text, tags: %w(u))
    end

    def test_should_allow_custom_tags
      text = "<u>foo</u>"
      assert_equal text, safe_list_sanitize(text, tags: %w(u))
    end

    def test_should_allow_only_custom_tags
      text = "<u>foo</u> with <i>bar</i>"
      assert_equal "<u>foo</u> with bar", safe_list_sanitize(text, tags: %w(u))
    end

    def test_should_allow_custom_tags_with_attributes
      text = %(<blockquote cite="http://example.com/">foo</blockquote>)
      assert_equal text, safe_list_sanitize(text)
    end

    def test_should_allow_custom_tags_with_custom_attributes
      text = %(<blockquote foo="bar">Lorem ipsum</blockquote>)
      assert_equal text, safe_list_sanitize(text, attributes: ["foo"])
    end

    def test_scrub_style_if_style_attribute_option_is_passed
      input = '<p style="color: #000; background-image: url(http://www.ragingplatypus.com/i/cam-full.jpg);"></p>'
      actual = safe_list_sanitize(input, attributes: %w(style))

      assert_includes(['<p style="color: #000;"></p>', '<p style="color:#000;"></p>'], actual)
    end

    def test_should_raise_argument_error_if_tags_is_not_enumerable
      assert_raises ArgumentError do
        safe_list_sanitize("<a>some html</a>", tags: "foo")
      end
    end

    def test_should_raise_argument_error_if_attributes_is_not_enumerable
      assert_raises ArgumentError do
        safe_list_sanitize("<a>some html</a>", attributes: "foo")
      end
    end

    def test_should_not_accept_non_loofah_inheriting_scrubber
      scrubber = Object.new
      def scrubber.scrub(node); node.name = "h1"; end

      assert_raises Loofah::ScrubberNotFound do
        safe_list_sanitize("<a>some html</a>", scrubber: scrubber)
      end
    end

    def test_should_accept_loofah_inheriting_scrubber
      scrubber = Loofah::Scrubber.new
      def scrubber.scrub(node); node.replace("<h1>#{node.inner_html}</h1>"); end

      html = "<script>hello!</script>"
      assert_equal "<h1>hello!</h1>", safe_list_sanitize(html, scrubber: scrubber)
    end

    def test_should_accept_loofah_scrubber_that_wraps_a_block
      scrubber = Loofah::Scrubber.new { |node| node.replace("<h1>#{node.inner_html}</h1>") }
      html = "<script>hello!</script>"
      assert_equal "<h1>hello!</h1>", safe_list_sanitize(html, scrubber: scrubber)
    end

    def test_custom_scrubber_takes_precedence_over_other_options
      scrubber = Loofah::Scrubber.new { |node| node.replace("<h1>#{node.inner_html}</h1>") }
      html = "<script>hello!</script>"
      assert_equal "<h1>hello!</h1>", safe_list_sanitize(html, scrubber: scrubber, tags: ["foo"])
    end

    def test_should_strip_src_attribute_in_img_with_bad_protocols
      assert_sanitized %(<img src="javascript:bang" title="1">), %(<img title="1">)
    end

    def test_should_strip_href_attribute_in_a_with_bad_protocols
      assert_sanitized %(<a href="javascript:bang" title="1">boo</a>), %(<a title="1">boo</a>)
    end

    def test_should_block_script_tag
      assert_sanitized %(<SCRIPT\nSRC=http://ha.ckers.org/xss.js></SCRIPT>), ""
    end

    def test_should_not_fall_for_xss_image_hack_with_uppercase_tags
      assert_sanitized %(<IMG """><SCRIPT>alert("XSS")</SCRIPT>">), %(<img>alert("XSS")"&gt;)
    end

    [%(<IMG SRC="javascript:alert('XSS');">),
     %(<IMG SRC=javascript:alert('XSS')>),
     %(<IMG SRC=JaVaScRiPt:alert('XSS')>),
     %(<IMG SRC=javascript:alert(&quot;XSS&quot;)>),
     %(<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>),
     %(<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>),
     %(<IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>),
     %(<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>),
     %(<IMG SRC="jav\tascript:alert('XSS');">),
     %(<IMG SRC="jav&#x09;ascript:alert('XSS');">),
     %(<IMG SRC="jav&#x0A;ascript:alert('XSS');">),
     %(<IMG SRC="jav&#x0D;ascript:alert('XSS');">),
     %(<IMG SRC=" &#14;  javascript:alert('XSS');">),
     %(<IMG SRC="javascript&#x3a;alert('XSS');">),
     %(<IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>)].each do |img_hack|
      define_method "test_should_not_fall_for_xss_image_hack_#{img_hack}" do
        assert_sanitized img_hack, "<img>"
      end
    end

    def test_should_sanitize_tag_broken_up_by_null
      input = %(<SCR\0IPT>alert(\"XSS\")</SCR\0IPT>)
      result = safe_list_sanitize(input)
      acceptable_results = [
        # libxml2
        "",
        # xerces+neko
        'alert("XSS")',
      ]

      assert_includes(acceptable_results, result)
    end

    def test_should_sanitize_invalid_script_tag
      assert_sanitized %(<SCRIPT/XSS SRC="http://ha.ckers.org/xss.js"></SCRIPT>), ""
    end

    def test_should_sanitize_script_tag_with_multiple_open_brackets
      assert_sanitized %(<<SCRIPT>alert("XSS");//<</SCRIPT>), "&lt;alert(\"XSS\");//&lt;"
    end

    def test_should_sanitize_script_tag_with_multiple_open_brackets_2
      input = %(<iframe src=http://ha.ckers.org/scriptlet.html\n<a)
      result = safe_list_sanitize(input)
      acceptable_results = [
        # libxml2
        "",
        # xerces+neko
        "&lt;a",
      ]

      assert_includes(acceptable_results, result)
    end

    def test_should_sanitize_unclosed_script
      assert_sanitized %(<SCRIPT SRC=http://ha.ckers.org/xss.js?<B>), ""
    end

    def test_should_sanitize_half_open_scripts
      input = %(<IMG SRC="javascript:alert('XSS')")
      result = safe_list_sanitize(input)
      acceptable_results = [
        # libxml2
        "<img>",
        # libgumbo
        "",
      ]

      assert_includes(acceptable_results, result)
    end

    def test_should_not_fall_for_ridiculous_hack
      img_hack = %(<IMG\nSRC\n=\n"\nj\na\nv\na\ns\nc\nr\ni\np\nt\n:\na\nl\ne\nr\nt\n(\n'\nX\nS\nS\n'\n)\n"\n>)
      assert_sanitized img_hack, "<img>"
    end

    def test_should_sanitize_attributes
      input = %(<SPAN title="'><script>alert()</script>">blah</SPAN>)
      result = safe_list_sanitize(input)
      acceptable_results = [
        # libxml2
        %(<span title="'&gt;&lt;script&gt;alert()&lt;/script&gt;">blah</span>),
        # libgumbo
        # this looks scary, but it's fine. for a more detailed analysis check out:
        # https://github.com/discourse/discourse/pull/21522#issuecomment-1545697968
        %(<span title="'><script>alert()</script>">blah</span>)
      ]

      assert_includes(acceptable_results, result)
    end

    def test_should_sanitize_invalid_tag_names
      assert_sanitized(%(a b c<script/XSS src="http://ha.ckers.org/xss.js"></script>d e f), "a b cd e f")
    end

    def test_should_sanitize_non_alpha_and_non_digit_characters_in_tags
      assert_sanitized('<a onclick!#$%&()*~+-_.,:;?@[/|\]^`=alert("XSS")>foo</a>', "<a>foo</a>")
    end

    def test_should_sanitize_invalid_tag_names_in_single_tags
      input = %(<img/src="http://ha.ckers.org/xss.js"/>)
      result = safe_list_sanitize(input)
      acceptable_results = [
        # libxml2
        "<img>",
        # libgumbo
        %(<img src="http://ha.ckers.org/xss.js">),
      ]

      assert_includes(acceptable_results, result)
    end

    def test_should_sanitize_img_dynsrc_lowsrc
      assert_sanitized(%(<img lowsrc="javascript:alert('XSS')" />), "<img>")
    end

    def test_should_sanitize_img_vbscript
      assert_sanitized %(<img src='vbscript:msgbox("XSS")' />), "<img>"
    end

    def test_should_sanitize_cdata_section
      input = "<![CDATA[<span>section</span>]]>"
      result = safe_list_sanitize(input)
      acceptable_results = [
        # libxml2 = 2.9.14
        %{&lt;![CDATA[<span>section</span>]]&gt;},
        # other libxml2
        %{section]]&gt;},
        # xerces+neko
        "",
      ]

      assert_includes(acceptable_results, result)
    end

    def test_should_sanitize_unterminated_cdata_section
      input = "<![CDATA[<span>neverending..."
      result = safe_list_sanitize(input)

      acceptable_results = [
        # libxml2 = 2.9.14
        %{&lt;![CDATA[<span>neverending...</span>},
        # other libxml2
        %{neverending...},
        # xerces+neko
        ""
      ]

      assert_includes(acceptable_results, result)
    end

    def test_should_not_mangle_urls_with_ampersand
      assert_sanitized %{<a href=\"http://www.domain.com?var1=1&amp;var2=2\">my link</a>}
    end

    def test_should_sanitize_neverending_attribute
      # note that assert_dom_equal chokes in this case! so avoid using assert_sanitized
      assert_equal("<span class=\"\\\"></span>", safe_list_sanitize("<span class=\"\\\">"))
    end

    [
      %(<a href="javascript&#x3a;alert('XSS');">),
      %(<a href="javascript&#x003a;alert('XSS');">),
      %(<a href="javascript&#x3A;alert('XSS');">),
      %(<a href="javascript&#x003A;alert('XSS');">)
    ].each_with_index do |enc_hack, i|
      define_method "test_x03a_handling_#{i + 1}" do
        assert_sanitized enc_hack, "<a></a>"
      end
    end

    def test_x03a_legitimate
      assert_sanitized %(<a href="http&#x3a;//legit">asdf</a>), %(<a href="http://legit">asdf</a>)
      assert_sanitized %(<a href="http&#x3A;//legit">asdf</a>), %(<a href="http://legit">asdf</a>)
    end

    def test_sanitize_ascii_8bit_string
      safe_list_sanitize("<div><a>hello</a></div>".encode("ASCII-8BIT")).tap do |sanitized|
        assert_equal "<div><a>hello</a></div>", sanitized
        assert_equal Encoding::UTF_8, sanitized.encoding
      end
    end

    def test_sanitize_data_attributes
      assert_sanitized %(<a href="/blah" data-method="post">foo</a>), %(<a href="/blah">foo</a>)
      assert_sanitized %(<a data-remote="true" data-type="script" data-method="get" data-cross-domain="true" href="attack.js">Launch the missiles</a>), %(<a href="attack.js">Launch the missiles</a>)
    end

    def test_allow_data_attribute_if_requested
      text = %(<a data-foo="foo">foo</a>)
      assert_equal %(<a data-foo="foo">foo</a>), safe_list_sanitize(text, attributes: ["data-foo"])
    end

    # https://developer.mozilla.org/en-US/docs/Glossary/Void_element
    VOID_ELEMENTS = %w[area base br col embed hr img input keygen link meta param source track wbr]

    %w(strong em b i p code pre tt samp kbd var sub
       sup dfn cite big small address hr br div span h1 h2 h3 h4 h5 h6 ul ol li dl dt dd abbr
       acronym a img blockquote del ins time).each do |tag_name|
      define_method "test_default_safelist_should_allow_#{tag_name}" do
        if VOID_ELEMENTS.include?(tag_name)
          assert_sanitized("<#{tag_name}>")
        else
          assert_sanitized("<#{tag_name}>foo</#{tag_name}>")
        end
      end
    end

    def test_datetime_attribute
      assert_sanitized("<time datetime=\"2023-01-01\">Today</time>")
    end

    def test_abbr_attribute
      scope_allowed_tags(%w(table tr th td)) do
        assert_sanitized(%(<table><tr><td abbr="UK">United Kingdom</td></tr></table>))
      end
    end

    def test_uri_escaping_of_href_attr_in_a_tag_in_safe_list_sanitizer
      html = %{<a href='examp<!--" unsafeattr=foo()>-->le.com'>test</a>}

      text = safe_list_sanitize(html)

      acceptable_results = [
        # nokogiri's vendored+patched libxml2 (0002-Update-entities-to-remove-handling-of-ssi.patch)
        %{<a href="examp&lt;!--%22%20unsafeattr=foo()&gt;--&gt;le.com">test</a>},
        # system libxml2
        %{<a href="examp<!--%22%20unsafeattr=foo()>-->le.com">test</a>},
        # xerces+neko
        %{<a href="examp&lt;!--%22 unsafeattr=foo()&gt;--&gt;le.com">test</a>}
      ]

      assert_includes(acceptable_results, text)
    end

    def test_uri_escaping_of_src_attr_in_a_tag_in_safe_list_sanitizer
      html = %{<a src='examp<!--" unsafeattr=foo()>-->le.com'>test</a>}

      text = safe_list_sanitize(html)

      acceptable_results = [
        # nokogiri's vendored+patched libxml2 (0002-Update-entities-to-remove-handling-of-ssi.patch)
        %{<a src="examp&lt;!--%22%20unsafeattr=foo()&gt;--&gt;le.com">test</a>},
        # system libxml2
        %{<a src="examp<!--%22%20unsafeattr=foo()>-->le.com">test</a>},
        # xerces+neko
        %{<a src="examp&lt;!--%22 unsafeattr=foo()&gt;--&gt;le.com">test</a>}
      ]

      assert_includes(acceptable_results, text)
    end

    def test_uri_escaping_of_name_attr_in_a_tag_in_safe_list_sanitizer
      html = %{<a name='examp<!--" unsafeattr=foo()>-->le.com'>test</a>}

      text = safe_list_sanitize(html)

      acceptable_results = [
        # nokogiri's vendored+patched libxml2 (0002-Update-entities-to-remove-handling-of-ssi.patch)
        %{<a name="examp&lt;!--%22%20unsafeattr=foo()&gt;--&gt;le.com">test</a>},
        # system libxml2
        %{<a name="examp<!--%22%20unsafeattr=foo()>-->le.com">test</a>},
        # xerces+neko
        %{<a name="examp&lt;!--%22 unsafeattr=foo()&gt;--&gt;le.com">test</a>}
      ]

      assert_includes(acceptable_results, text)
    end

    def test_uri_escaping_of_name_action_in_a_tag_in_safe_list_sanitizer
      html = %{<a action='examp<!--" unsafeattr=foo()>-->le.com'>test</a>}

      text = safe_list_sanitize(html, attributes: ["action"])

      acceptable_results = [
        # nokogiri's vendored+patched libxml2 (0002-Update-entities-to-remove-handling-of-ssi.patch)
        %{<a action="examp&lt;!--%22%20unsafeattr=foo()&gt;--&gt;le.com">test</a>},
        # system libxml2
        %{<a action="examp<!--%22%20unsafeattr=foo()>-->le.com">test</a>},
        # xerces+neko
        %{<a action="examp&lt;!--%22 unsafeattr=foo()&gt;--&gt;le.com">test</a>},
      ]

      assert_includes(acceptable_results, text)
    end

    def test_exclude_node_type_processing_instructions
      input = "<div>text</div><?div content><b>text</b>"
      result = safe_list_sanitize(input)
      acceptable_results = [
        # jruby cyberneko (nokogiri < 1.14.0)
        "<div>text</div>",
        # everything else
        "<div>text</div><b>text</b>",
      ]

      assert_includes(acceptable_results, result)
    end

    def test_exclude_node_type_comment
      assert_equal("<div>text</div><b>text</b>", safe_list_sanitize("<div>text</div><!-- comment --><b>text</b>"))
    end

    %w[text/plain text/css image/png image/gif image/jpeg].each do |mediatype|
      define_method "test_mediatype_#{mediatype}_allowed" do
        input = %Q(<img src="data:#{mediatype};base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4=">)
        expected = input
        actual = safe_list_sanitize(input)
        assert_equal(expected, actual)

        input = %Q(<img src="DATA:#{mediatype};base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4=">)
        expected = input
        actual = safe_list_sanitize(input)
        assert_equal(expected, actual)
      end
    end

    def test_mediatype_text_html_disallowed
      input = '<img src="data:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4=">'
      expected = "<img>"
      actual = safe_list_sanitize(input)
      assert_equal(expected, actual)

      input = '<img src="DATA:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4=">'
      expected = "<img>"
      actual = safe_list_sanitize(input)
      assert_equal(expected, actual)
    end

    def test_mediatype_image_svg_xml_disallowed
      input = '<img src="data:image/svg+xml;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4=">'
      expected = "<img>"
      actual = safe_list_sanitize(input)
      assert_equal(expected, actual)

      input = '<img src="DATA:image/svg+xml;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4=">'
      expected = "<img>"
      actual = safe_list_sanitize(input)
      assert_equal(expected, actual)
    end

    def test_mediatype_other_disallowed
      input = '<a href="data:foo;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4=">foo</a>'
      expected = "<a>foo</a>"
      actual = safe_list_sanitize(input)
      assert_equal(expected, actual)

      input = '<a href="DATA:foo;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4=">foo</a>'
      expected = "<a>foo</a>"
      actual = safe_list_sanitize(input)
      assert_equal(expected, actual)
    end

    def test_scrubbing_svg_attr_values_that_allow_ref
      input = '<div fill="yellow url(http://bad.com/) #fff">hey</div>'
      expected = '<div fill="yellow #fff">hey</div>'
      actual = scope_allowed_attributes %w(fill) do
        safe_list_sanitize(input)
      end

      assert_equal(expected, actual)
    end

    def test_style_with_css_payload
      input, tags = "<style>div > span { background: \"red\"; }</style>", ["style"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<style>div &gt; span { background: \"red\"; }</style>",
        # libgumbo
        "<style>div > span { background: \"red\"; }</style>",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_combination_of_select_and_style_with_css_payload
      input, tags = "<select><style>div > span { background: \"red\"; }</style></select>", ["select", "style"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<select><style>div &gt; span { background: \"red\"; }</style></select>",
        # libgumbo
        "<select>div &gt; span { background: \"red\"; }</select>",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_combination_of_select_and_style_with_script_payload
      input, tags = "<select><style><script>alert(1)</script></style></select>", ["select", "style"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<select><style>&lt;script&gt;alert(1)&lt;/script&gt;</style></select>",
        # libgumbo
        "<select>alert(1)</select>",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_combination_of_svg_and_style_with_script_payload
      input, tags = "<svg><style><script>alert(1)</script></style></svg>", ["svg", "style"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<svg><style>&lt;script&gt;alert(1)&lt;/script&gt;</style></svg>",
        # libgumbo
        "<svg><style></style></svg>",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_combination_of_math_and_style_with_img_payload
      input, tags = "<math><style><img src=x onerror=alert(1)></style></math>", ["math", "style"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<math><style>&lt;img src=x onerror=alert(1)&gt;</style></math>",
        # libgumbo
        "<math><style></style></math>",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_combination_of_math_and_style_with_img_payload_2
      input, tags = "<math><style><img src=x onerror=alert(1)></style></math>", ["math", "style", "img"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<math><style>&lt;img src=x onerror=alert(1)&gt;</style></math>",
        # libgumbo
        "<math><style></style></math><img src=\"x\">",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_combination_of_svg_and_style_with_img_payload
      input, tags = "<svg><style><img src=x onerror=alert(1)></style></svg>", ["svg", "style"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<svg><style>&lt;img src=x onerror=alert(1)&gt;</style></svg>",
        # libgumbo
        "<svg><style></style></svg>",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_combination_of_svg_and_style_with_img_payload_2
      input, tags = "<svg><style><img src=x onerror=alert(1)></style></svg>", ["svg", "style", "img"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<svg><style>&lt;img src=x onerror=alert(1)&gt;</style></svg>",
        # libgumbo
        "<svg><style></style></svg><img src=\"x\">",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_combination_of_svg_and_style_with_escaped_img_payload
      # https://hackerone.com/reports/2503220
      input, tags = "<svg><style>&lt;img src onerror=alert(1)>", ["svg", "style"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<svg><style>&amp;lt;img src onerror=alert(1)&gt;</style></svg>",
        # libgumbo
        "<svg><style>&lt;img src onerror=alert(1)&gt;</style></svg>",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_combination_of_math_and_style_with_escaped_img_payload
      # https://hackerone.com/reports/2503220
      input, tags = "<math><style>&lt;img src onerror=alert(1)>", ["math", "style"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<math><style>&amp;lt;img src onerror=alert(1)&gt;</style></math>",
        # libgumbo
        "<math><style>&lt;img src onerror=alert(1)&gt;</style></math>",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_combination_of_style_and_disallowed_svg_with_script_payload
      # https://hackerone.com/reports/2519936
      input, tags = "<svg><style><style class='</style><script>alert(1)</script>'>", ["style"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<style>&lt;style class='</style>alert(1)'&gt;",
        # libgumbo
        "",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_combination_of_style_and_disallowed_math_with_script_payload
      # https://hackerone.com/reports/2519936
      input, tags = "<math><style><style class='</style><script>alert(1)</script>'>", ["style"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<style>&lt;style class='</style>alert(1)'&gt;",
        # libgumbo
        "",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_math_with_disallowed_mtext_and_img_payload
      # https://hackerone.com/reports/2519941
      input, tags = "<math><mtext><table><mglyph><style><img src=: onerror=alert(1)>", ["math", "style"]
      actual = safe_list_sanitize(input, tags: tags)
      acceptable_results = [
        # libxml2
        "<math><style>&lt;img src=: onerror=alert(1)&gt;</style></math>",
        # libgumbo
        "<math></math>",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_should_sanitize_illegal_style_properties
      raw      = %(display:block; position:absolute; left:0; top:0; width:100%; height:100%; z-index:1; background-color:black; background-image:url(http://www.ragingplatypus.com/i/cam-full.jpg); background-x:center; background-y:center; background-repeat:repeat;)
      expected = %(display:block;width:100%;height:100%;background-color:black;background-x:center;background-y:center;)
      assert_equal expected, sanitize_css(raw)
    end

    def test_should_sanitize_with_trailing_space
      raw = "display:block; "
      expected = "display:block;"
      assert_equal expected, sanitize_css(raw)
    end

    def test_should_sanitize_xul_style_attributes
      raw = %(-moz-binding:url('http://ha.ckers.org/xssmoz.xml#xss'))
      assert_equal "", sanitize_css(raw)
    end

    def test_should_sanitize_div_background_image_unicode_encoded
      [
        convert_to_css_hex("url(javascript:alert(1))", false),
        convert_to_css_hex("url(javascript:alert(1))", true),
        convert_to_css_hex("url(https://example.com)", false),
        convert_to_css_hex("url(https://example.com)", true),
      ].each do |propval|
        raw = "background-image:" + propval
        assert_empty(sanitize_css(raw))
      end
    end

    def test_should_allow_div_background_image_unicode_encoded_safe_functions
      [
        convert_to_css_hex("rgb(255,0,0)", false),
        convert_to_css_hex("rgb(255,0,0)", true),
      ].each do |propval|
        raw = "background-image:" + propval

        assert_includes(sanitize_css(raw), "background-image")
      end
    end

    def test_should_sanitize_div_style_expression
      raw = %(width: expression(alert('XSS'));)
      assert_equal "", sanitize_css(raw)
    end

    def test_should_sanitize_across_newlines
      raw = %(\nwidth:\nexpression(alert('XSS'));\n)
      assert_equal "", sanitize_css(raw)
    end

    def test_should_prune_mglyph
      # https://hackerone.com/reports/2519936
      input = "<math><mtext><table><mglyph><style><img src=: onerror=alert(1)>"
      tags = %w(math mtext table mglyph style)

      actual = nil
      assert_output(nil, /WARNING: 'mglyph' tags cannot be allowed by the PermitScrubber/) do
        actual = safe_list_sanitize(input, tags: tags)
      end

      acceptable_results = [
        # libxml2
        "<math><mtext><table><style>&lt;img src=: onerror=alert(1)&gt;</style></table></mtext></math>",
        # libgumbo
        "<math><mtext><style><img src=: onerror=alert(1)></style><table></table></mtext></math>",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_should_prune_malignmark
      # https://hackerone.com/reports/2519936
      input = "<math><mtext><table><malignmark><style><img src=: onerror=alert(1)>"
      tags = %w(math mtext table malignmark style)

      actual = nil
      assert_output(nil, /WARNING: 'malignmark' tags cannot be allowed by the PermitScrubber/) do
        actual = safe_list_sanitize(input, tags: tags)
      end

      acceptable_results = [
        # libxml2
        "<math><mtext><table><style>&lt;img src=: onerror=alert(1)&gt;</style></table></mtext></math>",
        # libgumbo
        "<math><mtext><style><img src=: onerror=alert(1)></style><table></table></mtext></math>",
      ]

      assert_includes(acceptable_results, actual)
    end

    def test_should_prune_noscript
      # https://hackerone.com/reports/2509647
      input, tags = "<div><noscript><p id='</noscript><script>alert(1)</script>'></noscript>", ["p", "div", "noscript"]
      actual = nil
      assert_output(nil, /WARNING: 'noscript' tags cannot be allowed by the PermitScrubber/) do
        actual = safe_list_sanitize(input, tags: tags, attributes: %w(id))
      end

      acceptable_results = [
        # libxml2
        "<div><p id=\"&lt;/noscript&gt;&lt;script&gt;alert(1)&lt;/script&gt;\"></p></div>",
        # libgumbo
        "<div><p id=\"</noscript><script>alert(1)</script>\"></p></div>",
      ]

      assert_includes(acceptable_results, actual)
    end

    protected
      def safe_list_sanitize(input, options = {})
        module_under_test::SafeListSanitizer.new.sanitize(input, options)
      end

      def assert_sanitized(input, expected = nil)
        assert_equal((expected || input), safe_list_sanitize(input))
      end

      def scope_allowed_tags(tags)
        old_tags = module_under_test::SafeListSanitizer.allowed_tags
        module_under_test::SafeListSanitizer.allowed_tags = tags
        yield module_under_test::SafeListSanitizer.new
      ensure
        module_under_test::SafeListSanitizer.allowed_tags = old_tags
      end

      def scope_allowed_attributes(attributes)
        old_attributes = module_under_test::SafeListSanitizer.allowed_attributes
        module_under_test::SafeListSanitizer.allowed_attributes = attributes
        yield module_under_test::SafeListSanitizer.new
      ensure
        module_under_test::SafeListSanitizer.allowed_attributes = old_attributes
      end

      def sanitize_css(input)
        module_under_test::SafeListSanitizer.new.sanitize_css(input)
      end

      # note that this is used for testing CSS hex encoding: \\[0-9a-f]{1,6}
      def convert_to_css_hex(string, escape_parens = false)
        string.chars.map do |c|
          if !escape_parens && (c == "(" || c == ")")
            c
          else
            format('\00%02X', c.ord)
          end
        end.join
      end
  end

  class HTML4SafeListSanitizerTest < Minitest::Test
    @module_under_test = Rails::HTML4
    include SafeListSanitizerTest
  end

  class HTML5SafeListSanitizerTest < Minitest::Test
    @module_under_test = Rails::HTML5
    include SafeListSanitizerTest

    def test_should_not_be_vulnerable_to_nokogiri_foreign_style_serialization_bug
      # https://hackerone.com/reports/2503220
      input = "<svg><style>&lt;img src onerror=alert(1)>"
      result = Rails::HTML5::SafeListSanitizer.new.sanitize(input, tags: ["svg", "style"])
      browser = Nokogiri::HTML5::Document.parse(result)
      xss = browser.at_xpath("//img/@onerror")

      assert_nil(xss)
    end

    def test_should_not_be_vulnerable_to_ns_confusion_2519936
      # https://hackerone.com/reports/2519936
      input = "<math><style><style class='</style><script>alert(1)</script>'>"
      result = Rails::HTML5::SafeListSanitizer.new.sanitize(input, tags: ["style"])
      browser = Nokogiri::HTML5::Document.parse(result)
      xss = browser.at_xpath("//script")

      assert_nil(xss)
    end

    def test_should_not_be_vulnerable_to_ns_confusion_2519941
      # https://hackerone.com/reports/2519941
      input = "<math><mtext><table><mglyph><style><img src=: onerror=alert(1)>"
      result = Rails::HTML5::SafeListSanitizer.new.sanitize(input, tags: %w(math style))
      browser = Nokogiri::HTML5::Document.parse(result)
      xss = browser.at_xpath("//img/@onerror")

      assert_nil(xss)
    end

    def test_should_not_be_vulnerable_to_mglyph_namespace_confusion
      # https://hackerone.com/reports/2519936
      input = "<math><mtext><table><mglyph><style><img src=: onerror=alert(1)>"
      tags = %w(math mtext table mglyph style)

      result = nil
      assert_output(nil, /WARNING/) do
        result = safe_list_sanitize(input, tags: tags)
      end

      browser = Nokogiri::HTML5::Document.parse(result)
      xss = browser.at_xpath("//img/@onerror")

      assert_nil(xss)
    end

    def test_should_not_be_vulnerable_to_malignmark_namespace_confusion
      # https://hackerone.com/reports/2519936
      input = "<math><mtext><table><malignmark><style><img src=: onerror=alert(1)>"
      tags = %w(math mtext table malignmark style)

      result = nil
      assert_output(nil, /WARNING/) do
        result = safe_list_sanitize(input, tags: tags)
      end

      browser = Nokogiri::HTML5::Document.parse(result)
      xss = browser.at_xpath("//img/@onerror")

      assert_nil(xss)
    end

    def test_should_not_be_vulnerable_to_noscript_attacks
      # https://hackerone.com/reports/2509647
      skip("browser assertion requires parse_noscript_content_as_text") unless Nokogiri::VERSION >= "1.17"

      input = '<noscript><p id="</noscript><script>alert(1)</script>"></noscript>'

      result = nil
      assert_output(nil, /WARNING/) do
        result = Rails::HTML5::SafeListSanitizer.new.sanitize(input, tags: %w(p div noscript), attributes: %w(id class style))
      end

      browser = Nokogiri::HTML5::Document.parse(result, parse_noscript_content_as_text: true)
      xss = browser.at_xpath("//script")

      assert_nil(xss)
    end
  end if loofah_html5_support?
end
