# A visitor for converting a Sass tree into CSS.
class Sass::Tree::Visitors::ToCss < Sass::Tree::Visitors::Base
  # The source mapping for the generated CSS file. This is only set if
  # `build_source_mapping` is passed to the constructor and \{Sass::Engine#render} has been
  # run.
  attr_reader :source_mapping

  # @param build_source_mapping [Boolean] Whether to build a
  #   \{Sass::Source::Map} while creating the CSS output. The mapping will
  #   be available from \{#source\_mapping} after the visitor has completed.
  def initialize(build_source_mapping = false)
    @tabs = 0
    @line = 1
    @offset = 1
    @result = String.new("")
    @source_mapping = build_source_mapping ? Sass::Source::Map.new : nil
    @lstrip = nil
    @in_directive = false
  end

  # Runs the visitor on `node`.
  #
  # @param node [Sass::Tree::Node] The root node of the tree to convert to CSS>
  # @return [String] The CSS output.
  def visit(node)
    super
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:filename => node.filename, :line => node.line)
    raise e
  end

  protected

  def with_tabs(tabs)
    old_tabs, @tabs = @tabs, tabs
    yield
  ensure
    @tabs = old_tabs
  end

  # Associate all output produced in a block with a given node. Used for source
  # mapping.
  def for_node(node, attr_prefix = nil)
    return yield unless @source_mapping
    start_pos = Sass::Source::Position.new(@line, @offset)
    yield

    range_attr = attr_prefix ? :"#{attr_prefix}_source_range" : :source_range
    return if node.invisible? || !node.send(range_attr)
    source_range = node.send(range_attr)
    target_end_pos = Sass::Source::Position.new(@line, @offset)
    target_range = Sass::Source::Range.new(start_pos, target_end_pos, nil)
    @source_mapping.add(source_range, target_range)
  end

  def trailing_semicolon?
   @result.end_with?(";") && !@result.end_with?('\;')
  end

  # Move the output cursor back `chars` characters.
  def erase!(chars)
    return if chars == 0
    str = @result.slice!(-chars..-1)
    newlines = str.count("\n")
    if newlines > 0
      @line -= newlines
      @offset = @result[@result.rindex("\n") || 0..-1].size
    else
      @offset -= chars
    end
  end

  # Avoid allocating lots of new strings for `#output`. This is important
  # because `#output` is called all the time.
  NEWLINE = "\n"

  # Add `s` to the output string and update the line and offset information
  # accordingly.
  def output(s)
    if @lstrip
      s = s.gsub(/\A\s+/, "")
      @lstrip = false
    end

    newlines = s.count(NEWLINE)
    if newlines > 0
      @line += newlines
      @offset = s[s.rindex(NEWLINE)..-1].size
    else
      @offset += s.size
    end

    @result << s
  end

  # Strip all trailing whitespace from the output string.
  def rstrip!
    erase! @result.length - 1 - (@result.rindex(/[^\s]/) || -1)
  end

  # lstrip the first output in the given block.
  def lstrip
    old_lstrip = @lstrip
    @lstrip = true
    yield
  ensure
    @lstrip &&= old_lstrip
  end

  # Prepend `prefix` to the output string.
  def prepend!(prefix)
    @result.insert 0, prefix
    return unless @source_mapping

    line_delta = prefix.count("\n")
    offset_delta = prefix.gsub(/.*\n/, '').size
    @source_mapping.shift_output_offsets(offset_delta)
    @source_mapping.shift_output_lines(line_delta)
  end

  def visit_root(node)
    node.children.each do |child|
      next if child.invisible?
      visit(child)
      next if node.style == :compressed
      output "\n"
      next unless child.is_a?(Sass::Tree::DirectiveNode) && child.has_children && !child.bubbles?
      output "\n"
    end
    rstrip!
    if node.style == :compressed && trailing_semicolon?
      erase! 1
    end
    return "" if @result.empty?

    output "\n"

    unless @result.ascii_only?
      if node.style == :compressed
        # A byte order mark is sufficient to tell browsers that this
        # file is UTF-8 encoded, and will override any other detection
        # methods as per http://encoding.spec.whatwg.org/#decode-and-encode.
        prepend! "\uFEFF"
      else
        prepend! "@charset \"UTF-8\";\n"
      end
    end

    @result
  rescue Sass::SyntaxError => e
    e.sass_template ||= node.template
    raise e
  end

  def visit_charset(node)
    for_node(node) {output("@charset \"#{node.name}\";")}
  end

  def visit_comment(node)
    return if node.invisible?
    spaces = ('  ' * [@tabs - node.resolved_value[/^ */].size, 0].max)
    output(spaces)

    content = node.resolved_value.split("\n").join("\n" + spaces)
    if node.type == :silent
      content.gsub!(%r{^(\s*)//(.*)$}) {"#{$1}/*#{$2} */"}
    end
    if (node.style == :compact || node.style == :compressed) && node.type != :loud
      content.gsub!(%r{\n +(\* *(?!/))?}, ' ')
    end
    for_node(node) {output(content)}
  end

  def visit_directive(node)
    was_in_directive = @in_directive
    tab_str = '  ' * @tabs
    if !node.has_children || node.children.empty?
      output(tab_str)
      for_node(node) {output(node.resolved_value)}
      if node.has_children
        output("#{' ' unless node.style == :compressed}{}")
      elsif node.children.empty?
        output(";")
      end
      return
    end

    @in_directive ||= !node.is_a?(Sass::Tree::MediaNode)
    output(tab_str) if node.style != :compressed
    for_node(node) {output(node.resolved_value)}
    output(node.style == :compressed ? "{" : " {")
    output(node.style == :compact ? ' ' : "\n") if node.style != :compressed

    had_children = true
    first = true
    node.children.each do |child|
      next if child.invisible?
      if node.style == :compact
        if child.is_a?(Sass::Tree::PropNode)
          with_tabs(first || !had_children ? 0 : @tabs + 1) do
            visit(child)
            output(' ')
          end
        else
          unless had_children
            erase! 1
            output "\n"
          end

          if first
            lstrip {with_tabs(@tabs + 1) {visit(child)}}
          else
            with_tabs(@tabs + 1) {visit(child)}
          end

          rstrip!
          output "\n"
        end
        had_children = child.has_children
        first = false
      elsif node.style == :compressed
        unless had_children
          output(";") unless trailing_semicolon?
        end
        with_tabs(0) {visit(child)}
        had_children = child.has_children
      else
        with_tabs(@tabs + 1) {visit(child)}
        output "\n"
      end
    end
    rstrip!
    if node.style == :compressed && trailing_semicolon?
      erase! 1
    end
    if node.style == :expanded
      output("\n#{tab_str}")
    elsif node.style != :compressed
      output(" ")
    end
    output("}")
  ensure
    @in_directive = was_in_directive
  end

  def visit_media(node)
    with_tabs(@tabs + node.tabs) {visit_directive(node)}
    output("\n") if node.style != :compressed && node.group_end
  end

  def visit_supports(node)
    visit_media(node)
  end

  def visit_cssimport(node)
    visit_directive(node)
  end

  def visit_prop(node)
    return if node.resolved_value.empty? && !node.custom_property?
    tab_str = '  ' * (@tabs + node.tabs)
    output(tab_str)
    for_node(node, :name) {output(node.resolved_name)}
    output(":")
    output(" ") unless node.style == :compressed || node.custom_property?
    for_node(node, :value) do
      output(if node.custom_property?
               format_custom_property_value(node)
             else
               node.resolved_value
             end)
    end
    output(";") unless node.style == :compressed
  end

  def visit_rule(node)
    with_tabs(@tabs + node.tabs) do
      rule_separator = node.style == :compressed ? ',' : ', '
      line_separator =
        case node.style
        when :nested, :expanded; "\n"
        when :compressed; ""
        else; " "
        end
      rule_indent = '  ' * @tabs
      per_rule_indent, total_indent = if [:nested, :expanded].include?(node.style)
                                        [rule_indent, '']
                                      else
                                        ['', rule_indent]
                                      end

      joined_rules = node.resolved_rules.members.map do |seq|
        next if seq.invisible?
        rule_part = seq.to_s(style: node.style, placeholder: false)
        if node.style == :compressed
          rule_part.gsub!(/([^,])\s*\n\s*/m, '\1 ')
          rule_part.gsub!(/\s*([+>])\s*/m, '\1')
          rule_part.gsub!(/nth([^( ]*)\(([^)]*)\)/m) do |match|
            match.tr(" \t\n", "")
          end
          rule_part = Sass::Util.strip_except_escapes(rule_part)
        end
        rule_part
      end.compact.join(rule_separator)

      joined_rules.lstrip!
      joined_rules.gsub!(/\s*\n\s*/, "#{line_separator}#{per_rule_indent}")

      old_spaces = '  ' * @tabs
      if node.style != :compressed
        if node.options[:debug_info] && !@in_directive
          visit(debug_info_rule(node.debug_info, node.options))
          output "\n"
        elsif node.options[:trace_selectors]
          output("#{old_spaces}/* ")
          output(node.stack_trace.gsub("\n", "\n   #{old_spaces}"))
          output(" */\n")
        elsif node.options[:line_comments]
          output("#{old_spaces}/* line #{node.line}")

          if node.filename
            relative_filename =
              if node.options[:css_filename]
                begin
                  Sass::Util.relative_path_from(
                    node.filename, File.dirname(node.options[:css_filename])).to_s
                rescue ArgumentError
                  nil
                end
              end
            relative_filename ||= node.filename
            output(", #{relative_filename}")
          end

          output(" */\n")
        end
      end

      end_props, trailer, tabs = '', '', 0
      if node.style == :compact
        separator, end_props, bracket = ' ', ' ', ' { '
        trailer = "\n" if node.group_end
      elsif node.style == :compressed
        separator, bracket = ';', '{'
      else
        tabs = @tabs + 1
        separator, bracket = "\n", " {\n"
        trailer = "\n" if node.group_end
        end_props = (node.style == :expanded ? "\n" + old_spaces : ' ')
      end
      output(total_indent + per_rule_indent)
      for_node(node, :selector) {output(joined_rules)}
      output(bracket)

      with_tabs(tabs) do
        node.children.each_with_index do |child, i|
          if i > 0
            if separator.start_with?(";") && trailing_semicolon?
              erase! 1
            end
            output(separator)
          end
          visit(child)
        end
      end
      if node.style == :compressed && trailing_semicolon?
        erase! 1
      end

      output(end_props)
      output("}" + trailer)
    end
  end

  def visit_keyframerule(node)
    visit_directive(node)
  end

  private

  # Reformats the value of `node` so that it's nicely indented, preserving its
  # existing relative indentation.
  #
  # @param node [Sass::Script::Tree::PropNode] A custom property node.
  # @return [String]
  def format_custom_property_value(node)
    value = node.resolved_value.sub(/\n[ \t\r\f\n]*\Z/, ' ')
    if node.style == :compact || node.style == :compressed || !value.include?("\n")
      # Folding not involving newlines was done in the parser. We can safely
      # fold newlines here because tokens like strings can't contain literal
      # newlines, so we know any adjacent whitespace is tokenized as whitespace.
      return node.resolved_value.gsub(/[ \t\r\f]*\n[ \t\r\f\n]*/, ' ')
    end

    # Find the smallest amount of indentation in the custom property and use
    # that as the base indentation level.
    lines = value.split("\n")
    indented_lines = lines[1..-1]
    min_indentation = indented_lines.
      map {|line| line[/^[ \t]*/]}.
      reject {|line| line.empty?}.
      min_by {|line| line.length}

    # Limit the base indentation to the same indentation level as the node name
    # so that if *every* line is indented relative to the property name that's
    # preserved.
    if node.name_source_range
      base_indentation = min_indentation[0...node.name_source_range.start_pos.offset - 1]
    end

    lines.first + "\n" + indented_lines.join("\n").gsub(/^#{base_indentation}/, '  ' * @tabs)
  end

  def debug_info_rule(debug_info, options)
    node = Sass::Tree::DirectiveNode.resolved("@media -sass-debug-info")
    debug_info.map {|k, v| [k.to_s, v.to_s]}.to_a.each do |k, v|
      rule = Sass::Tree::RuleNode.new([""])
      rule.resolved_rules = Sass::Selector::CommaSequence.new(
        [Sass::Selector::Sequence.new(
          [Sass::Selector::SimpleSequence.new(
            [Sass::Selector::Element.new(k.to_s.gsub(/[^\w-]/, "\\\\\\0"), nil)],
            false)
          ])
        ])
      prop = Sass::Tree::PropNode.new([""], [""], :new)
      prop.resolved_name = "font-family"
      prop.resolved_value = Sass::SCSS::RX.escape_ident(v.to_s)
      rule << prop
      node << rule
    end
    node.options = options.merge(:debug_info => false,
                                 :line_comments => false,
                                 :style => :compressed)
    node
  end
end
