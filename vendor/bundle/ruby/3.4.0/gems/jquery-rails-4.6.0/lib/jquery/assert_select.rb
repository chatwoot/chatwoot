require 'rails/dom/testing/assertions/selector_assertions'

module Rails::Dom::Testing::Assertions::SelectorAssertions
  # Selects content from a JQuery response.  Patterned loosely on
  # assert_select_rjs.
  #
  # === Narrowing down
  #
  # With no arguments, asserts that one or more method calls are made.
  #
  # Use the +method+ argument to narrow down the assertion to only
  # statements that call that specific method.
  #
  # Use the +opt+ argument to narrow down the assertion to only statements
  # that pass +opt+ as the first argument.
  #
  # Use the +id+ argument to narrow down the assertion to only statements
  # that invoke methods on the result of using that identifier as a
  # selector.
  #
  # === Using blocks
  #
  # Without a block, +assert_select_jquery_ merely asserts that the
  # response contains one or more statements that match the conditions
  # specified above
  #
  # With a block +assert_select_jquery_ also asserts that the method call
  # passes a javascript escaped string containing HTML.  All such HTML
  # fragments are selected and passed to the block.  Nested assertions are
  # supported.
  #
  # === Examples
  #
  # # asserts that the #notice element is hidden
  # assert_select :hide, '#notice'
  #
  # # asserts that the #cart element is shown with a blind parameter
  # assert_select :show, :blind, '#cart'
  #
  # # asserts that #cart content contains a #current_item
  # assert_select :html, '#cart' do
  #   assert_select '#current_item'
  # end
  #
  # # asserts that #product append to a #product_list
  # assert_select_jquery :appendTo, '#product_list' do
  #   assert_select '.product'
  # end

  PATTERN_HTML  = "['\"]((\\\\\"|\\\\'|[^\"'])*)['\"]"
  PATTERN_UNICODE_ESCAPED_CHAR = /\\u([0-9a-zA-Z]{4})/
  SKELETAL_PATTERN = "(?:jQuery|\\$)\\(%s\\)\\.%s\\(%s\\)[;]?"

  def assert_select_jquery(*args, &block)
    jquery_method = args.first.is_a?(Symbol) ? args.shift : nil
    jquery_opt    = args.first.is_a?(Symbol) ? args.shift : nil
    id            = args.first.is_a?(String) ? escape_id(args.shift) : nil

    target_pattern   = "['\"]#{id || '.*'}['\"]"
    method_pattern   = "#{jquery_method || '\\w+'}"
    argument_pattern = jquery_opt ? "['\"]#{jquery_opt}['\"].*" : PATTERN_HTML

    # $("#id").show('blind', 1000);
    # $("#id").html("<div>something</div>");
    # $("#id").replaceWith("<div>something</div>");
    target_as_receiver_pattern = SKELETAL_PATTERN % [target_pattern, method_pattern, argument_pattern]

    # $("<div>something</div>").appendTo("#id");
    # $("<div>something</div>").prependTo("#id");
    target_as_argument_pattern = SKELETAL_PATTERN % [argument_pattern, method_pattern, target_pattern]

    # $("#id").remove();
    # $("#id").hide();
    argumentless_pattern = SKELETAL_PATTERN % [target_pattern, method_pattern, '']

    patterns = [target_as_receiver_pattern, target_as_argument_pattern]
    patterns << argumentless_pattern unless jquery_opt

    matched_pattern = nil
    patterns.each do |pattern|
      if response.body.match(Regexp.new(pattern))
        matched_pattern = pattern
        break
      end
    end

    unless matched_pattern
      opts = [jquery_method, jquery_opt, id].compact
      flunk "No JQuery call matches #{opts.inspect}"
    end

    if block_given?
      @selected ||= nil
      fragments = Nokogiri::HTML::Document.new.fragment

      if matched_pattern
        response.body.scan(Regexp.new(matched_pattern)).each do |match|
          flunk 'This function can\'t have HTML argument' if match.is_a?(String)

          doc = Nokogiri::HTML::DocumentFragment.parse(unescape_js(match.first))
          doc.children.each do |child|
            fragments << child if child.element?
          end
        end
      end

      begin
        in_scope, @selected = @selected, fragments
        yield
      ensure
        @selected = in_scope
      end
    end
  end

  private

    # Unescapes a JS string.
    def unescape_js(js_string)
      # js encodes double quotes and line breaks.
      unescaped= js_string.gsub('\"', '"')
      unescaped.gsub!('\\\'', "'")
      unescaped.gsub!(/\\\//, '/')
      unescaped.gsub!('\n', "\n")
      unescaped.gsub!('\076', '>')
      unescaped.gsub!('\074', '<')
      unescaped.gsub!(/\\\$/, '$')
      unescaped.gsub!(/\\`/, '`')
      # js encodes non-ascii characters.
      unescaped.gsub!(PATTERN_UNICODE_ESCAPED_CHAR) {|u| [$1.hex].pack('U*')}
      unescaped
    end

    def escape_id(selector)
      return unless selector

      id = selector.gsub('[', '\[')
      id.gsub!(']', '\]')
      id.gsub!('*', '\*')
      id.gsub!('(', '\(')
      id.gsub!(')', '\)')
      id.gsub!('.', '\.')
      id.gsub!('|', '\|')
      id.gsub!('^', '\^')
      id.gsub!('$', '\$')
      id.gsub!('+', "\\\\+")
      id.gsub!(',', '\,')

      id
    end
end
