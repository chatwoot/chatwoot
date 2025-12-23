require File.dirname(__FILE__) + '/../sass'
require 'sass/tree/node'
require 'sass/scss/css_parser'

module Sass
  # This class converts CSS documents into Sass or SCSS templates.
  # It works by parsing the CSS document into a {Sass::Tree} structure,
  # and then applying various transformations to the structure
  # to produce more concise and idiomatic Sass/SCSS.
  #
  # Example usage:
  #
  #     Sass::CSS.new("p { color: blue }").render(:sass) #=> "p\n  color: blue"
  #     Sass::CSS.new("p { color: blue }").render(:scss) #=> "p {\n  color: blue; }"
  class CSS
    # @param template [String] The CSS stylesheet.
    #   This stylesheet can be encoded using any encoding
    #   that can be converted to Unicode.
    #   If the stylesheet contains an `@charset` declaration,
    #   that overrides the Ruby encoding
    #   (see {file:SASS_REFERENCE.md#Encodings the encoding documentation})
    # @option options :old [Boolean] (false)
    #     Whether or not to output old property syntax
    #     (`:color blue` as opposed to `color: blue`).
    #     This is only meaningful when generating Sass code,
    #     rather than SCSS.
    # @option options :indent [String] ("  ")
    #     The string to use for indenting each line. Defaults to two spaces.
    def initialize(template, options = {})
      if template.is_a? IO
        template = template.read
      end

      @options = options.merge(:_convert => true)
      # Backwards compatibility
      @options[:old] = true if @options[:alternate] == false
      @template = template
      @checked_encoding = false
    end

    # Converts the CSS template into Sass or SCSS code.
    #
    # @param fmt [Symbol] `:sass` or `:scss`, designating the format to return.
    # @return [String] The resulting Sass or SCSS code
    # @raise [Sass::SyntaxError] if there's an error parsing the CSS template
    def render(fmt = :sass)
      check_encoding!
      build_tree.send("to_#{fmt}", @options).strip + "\n"
    rescue Sass::SyntaxError => err
      err.modify_backtrace(:filename => @options[:filename] || '(css)')
      raise err
    end

    # Returns the original encoding of the document.
    #
    # @return [Encoding, nil]
    # @raise [Encoding::UndefinedConversionError] if the source encoding
    #   cannot be converted to UTF-8
    # @raise [ArgumentError] if the document uses an unknown encoding with `@charset`
    def source_encoding
      check_encoding!
      @original_encoding
    end

    private

    def check_encoding!
      return if @checked_encoding
      @checked_encoding = true
      @template, @original_encoding = Sass::Util.check_sass_encoding(@template)
    end

    # Parses the CSS template and applies various transformations
    #
    # @return [Tree::Node] The root node of the parsed tree
    def build_tree
      root = Sass::SCSS::CssParser.new(@template, @options[:filename], nil).parse
      parse_selectors(root)
      expand_commas(root)
      nest_seqs(root)
      parent_ref_rules(root)
      flatten_rules(root)
      bubble_subject(root)
      fold_commas(root)
      dump_selectors(root)
      root
    end

    # Parse all the selectors in the document and assign them to
    # {Sass::Tree::RuleNode#parsed_rules}.
    #
    # @param root [Tree::Node] The parent node
    def parse_selectors(root)
      root.children.each do |child|
        next parse_selectors(child) if child.is_a?(Tree::DirectiveNode)
        next unless child.is_a?(Tree::RuleNode)
        parser = Sass::SCSS::CssParser.new(child.rule.first, child.filename, nil, child.line)
        child.parsed_rules = parser.parse_selector
      end
    end

    # Transform
    #
    #     foo, bar, baz
    #       color: blue
    #
    # into
    #
    #     foo
    #       color: blue
    #     bar
    #       color: blue
    #     baz
    #       color: blue
    #
    # @param root [Tree::Node] The parent node
    def expand_commas(root)
      root.children.map! do |child|
        # child.parsed_rules.members.size > 1 iff the rule contains a comma
        unless child.is_a?(Tree::RuleNode) && child.parsed_rules.members.size > 1
          expand_commas(child) if child.is_a?(Tree::DirectiveNode)
          next child
        end
        child.parsed_rules.members.map do |seq|
          node = Tree::RuleNode.new([])
          node.parsed_rules = make_cseq(seq)
          node.children = child.children
          node
        end
      end
      root.children.flatten!
    end

    # Make rules use nesting so that
    #
    #     foo
    #       color: green
    #     foo bar
    #       color: red
    #     foo baz
    #       color: blue
    #
    # becomes
    #
    #     foo
    #       color: green
    #       bar
    #         color: red
    #       baz
    #         color: blue
    #
    # @param root [Tree::Node] The parent node
    def nest_seqs(root)
      current_rule = nil
      root.children.map! do |child|
        unless child.is_a?(Tree::RuleNode)
          nest_seqs(child) if child.is_a?(Tree::DirectiveNode)
          next child
        end

        seq = first_seq(child)
        seq.members.reject! {|sseq| sseq == "\n"}
        first, rest = seq.members.first, seq.members[1..-1]

        if current_rule.nil? || first_sseq(current_rule) != first
          current_rule = Tree::RuleNode.new([])
          current_rule.parsed_rules = make_seq(first)
        end

        if rest.empty?
          current_rule.children += child.children
        else
          child.parsed_rules = make_seq(*rest)
          current_rule << child
        end

        current_rule
      end
      root.children.compact!
      root.children.uniq!

      root.children.each {|v| nest_seqs(v)}
    end

    # Make rules use parent refs so that
    #
    #     foo
    #       color: green
    #     foo.bar
    #       color: blue
    #
    # becomes
    #
    #     foo
    #       color: green
    #       &.bar
    #         color: blue
    #
    # @param root [Tree::Node] The parent node
    def parent_ref_rules(root)
      current_rule = nil
      root.children.map! do |child|
        unless child.is_a?(Tree::RuleNode)
          parent_ref_rules(child) if child.is_a?(Tree::DirectiveNode)
          next child
        end

        sseq = first_sseq(child)
        next child unless sseq.is_a?(Sass::Selector::SimpleSequence)

        firsts, rest = [sseq.members.first], sseq.members[1..-1]
        firsts.push rest.shift if firsts.first.is_a?(Sass::Selector::Parent)

        last_simple_subject = rest.empty? && sseq.subject?
        if current_rule.nil? || first_sseq(current_rule).members != firsts ||
            !!first_sseq(current_rule).subject? != !!last_simple_subject
          current_rule = Tree::RuleNode.new([])
          current_rule.parsed_rules = make_sseq(last_simple_subject, *firsts)
        end

        if rest.empty?
          current_rule.children += child.children
        else
          rest.unshift Sass::Selector::Parent.new
          child.parsed_rules = make_sseq(sseq.subject?, *rest)
          current_rule << child
        end

        current_rule
      end
      root.children.compact!
      root.children.uniq!

      root.children.each {|v| parent_ref_rules(v)}
    end

    # Flatten rules so that
    #
    #     foo
    #       bar
    #         color: red
    #
    # becomes
    #
    #     foo bar
    #       color: red
    #
    # and
    #
    #     foo
    #       &.bar
    #         color: blue
    #
    # becomes
    #
    #     foo.bar
    #       color: blue
    #
    # @param root [Tree::Node] The parent node
    def flatten_rules(root)
      root.children.each do |child|
        case child
        when Tree::RuleNode
          flatten_rule(child)
        when Tree::DirectiveNode
          flatten_rules(child)
        end
      end
    end

    # Flattens a single rule.
    #
    # @param rule [Tree::RuleNode] The candidate for flattening
    # @see #flatten_rules
    def flatten_rule(rule)
      while rule.children.size == 1 && rule.children.first.is_a?(Tree::RuleNode)
        child = rule.children.first

        if first_simple_sel(child).is_a?(Sass::Selector::Parent)
          rule.parsed_rules = child.parsed_rules.resolve_parent_refs(rule.parsed_rules)
        else
          rule.parsed_rules = make_seq(*(first_seq(rule).members + first_seq(child).members))
        end

        rule.children = child.children
      end

      flatten_rules(rule)
    end

    def bubble_subject(root)
      root.children.each do |child|
        bubble_subject(child) if child.is_a?(Tree::RuleNode) || child.is_a?(Tree::DirectiveNode)
        next unless child.is_a?(Tree::RuleNode) && !child.children.empty?
        next unless child.children.all? do |c|
          next unless c.is_a?(Tree::RuleNode)
          first_simple_sel(c).is_a?(Sass::Selector::Parent) && first_sseq(c).subject?
        end
        first_sseq(child).subject = true
        child.children.each {|c| first_sseq(c).subject = false}
      end
    end

    # Transform
    #
    #     foo
    #       bar
    #         color: blue
    #       baz
    #         color: blue
    #
    # into
    #
    #     foo
    #       bar, baz
    #         color: blue
    #
    # @param root [Tree::Node] The parent node
    def fold_commas(root)
      prev_rule = nil
      root.children.map! do |child|
        unless child.is_a?(Tree::RuleNode)
          fold_commas(child) if child.is_a?(Tree::DirectiveNode)
          next child
        end

        if prev_rule && prev_rule.children.map {|c| c.to_sass} == child.children.map {|c| c.to_sass}
          prev_rule.parsed_rules.members << first_seq(child)
          next nil
        end

        fold_commas(child)
        prev_rule = child
        child
      end
      root.children.compact!
    end

    # Dump all the parsed {Sass::Tree::RuleNode} selectors to strings.
    #
    # @param root [Tree::Node] The parent node
    def dump_selectors(root)
      root.children.each do |child|
        next dump_selectors(child) if child.is_a?(Tree::DirectiveNode)
        next unless child.is_a?(Tree::RuleNode)
        child.rule = [child.parsed_rules.to_s]
        dump_selectors(child)
      end
    end

    # Create a {Sass::Selector::CommaSequence}.
    #
    # @param seqs [Array<Sass::Selector::Sequence>]
    # @return [Sass::Selector::CommaSequence]
    def make_cseq(*seqs)
      Sass::Selector::CommaSequence.new(seqs)
    end

    # Create a {Sass::Selector::CommaSequence} containing only a single
    # {Sass::Selector::Sequence}.
    #
    # @param sseqs [Array<Sass::Selector::Sequence, String>]
    # @return [Sass::Selector::CommaSequence]
    def make_seq(*sseqs)
      make_cseq(Sass::Selector::Sequence.new(sseqs))
    end

    # Create a {Sass::Selector::CommaSequence} containing only a single
    # {Sass::Selector::Sequence} which in turn contains only a single
    # {Sass::Selector::SimpleSequence}.
    #
    # @param subject [Boolean] Whether this is a subject selector
    # @param sseqs [Array<Sass::Selector::Sequence, String>]
    # @return [Sass::Selector::CommaSequence]
    def make_sseq(subject, *sseqs)
      make_seq(Sass::Selector::SimpleSequence.new(sseqs, subject))
    end

    # Return the first {Sass::Selector::Sequence} in a {Sass::Tree::RuleNode}.
    #
    # @param rule [Sass::Tree::RuleNode]
    # @return [Sass::Selector::Sequence]
    def first_seq(rule)
      rule.parsed_rules.members.first
    end

    # Return the first {Sass::Selector::SimpleSequence} in a
    # {Sass::Tree::RuleNode}.
    #
    # @param rule [Sass::Tree::RuleNode]
    # @return [Sass::Selector::SimpleSequence, String]
    def first_sseq(rule)
      first_seq(rule).members.first
    end

    # Return the first {Sass::Selector::Simple} in a {Sass::Tree::RuleNode},
    # unless the rule begins with a combinator.
    #
    # @param rule [Sass::Tree::RuleNode]
    # @return [Sass::Selector::Simple?]
    def first_simple_sel(rule)
      sseq = first_sseq(rule)
      return unless sseq.is_a?(Sass::Selector::SimpleSequence)
      sseq.members.first
    end
  end
end
