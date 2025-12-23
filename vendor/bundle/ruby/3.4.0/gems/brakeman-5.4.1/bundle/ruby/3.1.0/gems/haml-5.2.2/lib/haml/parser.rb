# frozen_string_literal: true

require 'ripper'
require 'strscan'

module Haml
  class Parser
    include Haml::Util

    attr_reader :root

    # Designates an XHTML/XML element.
    ELEMENT         = ?%

    # Designates a `<div>` element with the given class.
    DIV_CLASS       = ?.

    # Designates a `<div>` element with the given id.
    DIV_ID          = ?#

    # Designates an XHTML/XML comment.
    COMMENT         = ?/

    # Designates an XHTML doctype or script that is never HTML-escaped.
    DOCTYPE         = ?!

    # Designates script, the result of which is output.
    SCRIPT          = ?=

    # Designates script that is always HTML-escaped.
    SANITIZE        = ?&

    # Designates script, the result of which is flattened and output.
    FLAT_SCRIPT     = ?~

    # Designates script which is run but not output.
    SILENT_SCRIPT   = ?-

    # When following SILENT_SCRIPT, designates a comment that is not output.
    SILENT_COMMENT  = ?#

    # Designates a non-parsed line.
    ESCAPE          = ?\\

    # Designates a block of filtered text.
    FILTER          = ?:

    # Designates a non-parsed line. Not actually a character.
    PLAIN_TEXT      = -1

    # Keeps track of the ASCII values of the characters that begin a
    # specially-interpreted line.
    SPECIAL_CHARACTERS   = [
      ELEMENT,
      DIV_CLASS,
      DIV_ID,
      COMMENT,
      DOCTYPE,
      SCRIPT,
      SANITIZE,
      FLAT_SCRIPT,
      SILENT_SCRIPT,
      ESCAPE,
      FILTER
    ].freeze

    # The value of the character that designates that a line is part
    # of a multiline string.
    MULTILINE_CHAR_VALUE = ?|

    # Regex to check for blocks with spaces around arguments. Not to be confused
    # with multiline script.
    # For example:
    #     foo.each do | bar |
    #       = bar
    #
    BLOCK_WITH_SPACES = /do\s*\|\s*[^\|]*\s+\|\z/

    MID_BLOCK_KEYWORDS = %w[else elsif rescue ensure end when].freeze
    START_BLOCK_KEYWORDS = %w[if begin case unless].freeze
    # Try to parse assignments to block starters as best as possible
    START_BLOCK_KEYWORD_REGEX = /(?:\w+(?:,\s*\w+)*\s*=\s*)?(#{START_BLOCK_KEYWORDS.join('|')})/
    BLOCK_KEYWORD_REGEX = /^-?\s*(?:(#{MID_BLOCK_KEYWORDS.join('|')})|#{START_BLOCK_KEYWORD_REGEX.source})\b/

    # The Regex that matches a Doctype command.
    DOCTYPE_REGEX = /(\d(?:\.\d)?)?\s*([a-z]*)\s*([^ ]+)?/i

    # The Regex that matches a literal string or symbol value
    LITERAL_VALUE_REGEX = /:(\w*)|(["'])((?!\\|\#\{|\#@|\#\$|\2).|\\.)*\2/

    ID_KEY    = 'id'.freeze
    CLASS_KEY = 'class'.freeze

    # Used for scanning old attributes, substituting the first '{'
    METHOD_CALL_PREFIX = 'a('

    def initialize(options)
      @options = Options.wrap(options)
      # Record the indent levels of "if" statements to validate the subsequent
      # elsif and else statements are indented at the appropriate level.
      @script_level_stack = []
      @template_index     = 0
      @template_tabs      = 0
    end

    def call(template)
      match = template.rstrip.scan(/(([ \t]+)?(.*?))(?:\Z|\r\n|\r|\n)/m)
      # discard the last match which is always blank
      match.pop
      @template = match.each_with_index.map do |(full, whitespace, text), index|
        Line.new(whitespace, text.rstrip, full, index, self, false)
      end
      # Append special end-of-document marker
      @template << Line.new(nil, '-#', '-#', @template.size, self, true)

      @root = @parent = ParseNode.new(:root)
      @flat = false
      @filter_buffer = nil
      @indentation = nil
      @line = next_line

      raise SyntaxError.new(Error.message(:indenting_at_start), @line.index) if @line.tabs != 0

      loop do
        next_line

        process_indent(@line) unless @line.text.empty?

        if flat?
          text = @line.full.dup
          text = "" unless text.gsub!(/^#{@flat_spaces}/, '')
          @filter_buffer << "#{text}\n"
          @line = @next_line
          next
        end

        @tab_up = nil
        process_line(@line) unless @line.text.empty?
        if block_opened? || @tab_up
          @template_tabs += 1
          @parent = @parent.children.last
        end

        if !flat? && @next_line.tabs - @line.tabs > 1
          raise SyntaxError.new(Error.message(:deeper_indenting, @next_line.tabs - @line.tabs), @next_line.index)
        end

        @line = @next_line
      end
      # Close all the open tags
      close until @parent.type == :root
      @root
    rescue Haml::Error => e
      e.backtrace.unshift "#{@options.filename}:#{(e.line ? e.line + 1 : @line.index + 1) + @options.line - 1}"
      raise
    end

    def compute_tabs(line)
      return 0 if line.text.empty? || !line.whitespace

      if @indentation.nil?
        @indentation = line.whitespace

        if @indentation.include?(?\s) && @indentation.include?(?\t)
          raise SyntaxError.new(Error.message(:cant_use_tabs_and_spaces), line.index)
        end

        @flat_spaces = @indentation * (@template_tabs+1) if flat?
        return 1
      end

      tabs = line.whitespace.length / @indentation.length
      return tabs if line.whitespace == @indentation * tabs
      return @template_tabs + 1 if flat? && line.whitespace =~ /^#{@flat_spaces}/

      message = Error.message(:inconsistent_indentation,
        human_indentation(line.whitespace),
        human_indentation(@indentation)
      )
      raise SyntaxError.new(message, line.index)
    end

    private

    # @private
    Line = Struct.new(:whitespace, :text, :full, :index, :parser, :eod) do
      alias_method :eod?, :eod

      # @private
      def tabs
        @tabs ||= parser.compute_tabs(self)
      end

      def strip!(from)
        self.text = text[from..-1]
        self.text.lstrip!
        self
      end
    end

    # @private
    ParseNode = Struct.new(:type, :line, :value, :parent, :children) do
      def initialize(*args)
        super
        self.children ||= []
      end

      def inspect
        %Q[(#{type} #{value.inspect}#{children.each_with_object(''.dup) {|c, s| s << "\n#{c.inspect.gsub!(/^/, '  ')}"}})].dup
      end
    end

    # @param [String] new - Hash literal including dynamic values.
    # @param [String] old - Hash literal including dynamic values or Ruby literal of multiple Hashes which MUST be interpreted as method's last arguments.
    DynamicAttributes = Struct.new(:new, :old) do
      undef :old=
      def old=(value)
        unless value =~ /\A{.*}\z/m
          raise ArgumentError.new('Old attributes must start with "{" and end with "}"')
        end
        self[:old] = value
      end

      # This will be a literal for Haml::Buffer#attributes's last argument, `attributes_hashes`.
      def to_literal
        [new, stripped_old].compact.join(', ')
      end

      private

      # For `%foo{ { foo: 1 }, bar: 2 }`, :old is "{ { foo: 1 }, bar: 2 }" and this method returns " { foo: 1 }, bar: 2 " for last argument.
      def stripped_old
        return nil if old.nil?
        old.sub!(/\A{/, '').sub!(/}\z/m, '')
      end
    end

    # Processes and deals with lowering indentation.
    def process_indent(line)
      return unless line.tabs <= @template_tabs && @template_tabs > 0

      to_close = @template_tabs - line.tabs
      to_close.times {|i| close unless to_close - 1 - i == 0 && continuation_script?(line.text)}
    end

    def continuation_script?(text)
      text[0] == SILENT_SCRIPT && mid_block_keyword?(text)
    end

    def mid_block_keyword?(text)
      MID_BLOCK_KEYWORDS.include?(block_keyword(text))
    end

    # Processes a single line of Haml.
    #
    # This method doesn't return anything; it simply processes the line and
    # adds the appropriate code to `@precompiled`.
    def process_line(line)
      case line.text[0]
      when DIV_CLASS; push div(line)
      when DIV_ID
        return push plain(line) if %w[{ @ $].include?(line.text[1])
        push div(line)
      when ELEMENT; push tag(line)
      when COMMENT; push comment(line.text[1..-1].lstrip)
      when SANITIZE
        return push plain(line.strip!(3), :escape_html) if line.text[1, 2] == '=='
        return push script(line.strip!(2), :escape_html) if line.text[1] == SCRIPT
        return push flat_script(line.strip!(2), :escape_html) if line.text[1] == FLAT_SCRIPT
        return push plain(line.strip!(1), :escape_html) if line.text[1] == ?\s || line.text[1..2] == '#{'
        push plain(line)
      when SCRIPT
        return push plain(line.strip!(2)) if line.text[1] == SCRIPT
        line.text = line.text[1..-1]
        push script(line)
      when FLAT_SCRIPT; push flat_script(line.strip!(1))
      when SILENT_SCRIPT
        return push haml_comment(line.text[2..-1]) if line.text[1] == SILENT_COMMENT
        push silent_script(line)
      when FILTER; push filter(line.text[1..-1].downcase)
      when DOCTYPE
        return push doctype(line.text) if line.text[0, 3] == '!!!'
        return push plain(line.strip!(3), false) if line.text[1, 2] == '=='
        return push script(line.strip!(2), false) if line.text[1] == SCRIPT
        return push flat_script(line.strip!(2), false) if line.text[1] == FLAT_SCRIPT
        return push plain(line.strip!(1), false) if line.text[1] == ?\s || line.text[1..2] == '#{'
        push plain(line)
      when ESCAPE
        line.text = line.text[1..-1]
        push plain(line)
      else; push plain(line)
      end
    end

    def block_keyword(text)
      return unless (keyword = text.scan(BLOCK_KEYWORD_REGEX)[0])
      keyword[0] || keyword[1]
    end

    def push(node)
      @parent.children << node
      node.parent = @parent
    end

    def plain(line, escape_html = nil)
      if block_opened?
        raise SyntaxError.new(Error.message(:illegal_nesting_plain), @next_line.index)
      end

      unless contains_interpolation?(line.text)
        return ParseNode.new(:plain, line.index + 1, :text => line.text)
      end

      escape_html = @options.escape_html && @options.mime_type != 'text/plain' if escape_html.nil?
      line.text = unescape_interpolation(line.text, escape_html)
      script(line, false)
    end

    def script(line, escape_html = nil, preserve = false)
      raise SyntaxError.new(Error.message(:no_ruby_code, '=')) if line.text.empty?
      line = handle_ruby_multiline(line)
      escape_html = @options.escape_html if escape_html.nil?

      keyword = block_keyword(line.text)
      check_push_script_stack(keyword)

      ParseNode.new(:script, line.index + 1, :text => line.text, :escape_html => escape_html,
        :preserve => preserve, :keyword => keyword)
    end

    def flat_script(line, escape_html = nil)
      raise SyntaxError.new(Error.message(:no_ruby_code, '~')) if line.text.empty?
      script(line, escape_html, :preserve)
    end

    def silent_script(line)
      raise SyntaxError.new(Error.message(:no_end), line.index) if line.text[1..-1].strip == 'end'

      line = handle_ruby_multiline(line)
      keyword = block_keyword(line.text)

      check_push_script_stack(keyword)

      if ["else", "elsif", "when"].include?(keyword)
        if @script_level_stack.empty?
          raise Haml::SyntaxError.new(Error.message(:missing_if, keyword), @line.index)
        end

        if keyword == 'when' and !@script_level_stack.last[2]
          if @script_level_stack.last[1] + 1 == @line.tabs
            @script_level_stack.last[1] += 1
          end
          @script_level_stack.last[2] = true
        end

        if @script_level_stack.last[1] != @line.tabs
          message = Error.message(:bad_script_indent, keyword, @script_level_stack.last[1], @line.tabs)
          raise Haml::SyntaxError.new(message, @line.index)
        end
      end

      ParseNode.new(:silent_script, @line.index + 1,
        :text => line.text[1..-1], :keyword => keyword)
    end

    def check_push_script_stack(keyword)
      if ["if", "case", "unless"].include?(keyword)
        # @script_level_stack contents are arrays of form
        # [:keyword, stack_level, other_info]
        @script_level_stack.push([keyword.to_sym, @line.tabs])
        @script_level_stack.last << false if keyword == 'case'
        @tab_up = true
      end
    end

    def haml_comment(text)
      if filter_opened?
        @flat = true
        @filter_buffer = String.new
        @filter_buffer << "#{text}\n" unless text.empty?
        text = @filter_buffer
        # If we don't know the indentation by now, it'll be set in Line#tabs
        @flat_spaces = @indentation * (@template_tabs+1) if @indentation
      end

      ParseNode.new(:haml_comment, @line.index + 1, :text => text)
    end

    def tag(line)
      tag_name, attributes, attributes_hashes, object_ref, nuke_outer_whitespace,
        nuke_inner_whitespace, action, value, last_line = parse_tag(line.text)

      preserve_tag = @options.preserve.include?(tag_name)
      nuke_inner_whitespace ||= preserve_tag
      escape_html = (action == '&' || (action != '!' && @options.escape_html))

      case action
      when '/'; self_closing = true
      when '~'; parse = preserve_script = true
      when '='
        parse = true
        if value[0] == ?=
          value = unescape_interpolation(value[1..-1].strip, escape_html)
          escape_html = false
        end
      when '&', '!'
        if value[0] == ?= || value[0] == ?~
          parse = true
          preserve_script = (value[0] == ?~)
          if value[1] == ?=
            value = unescape_interpolation(value[2..-1].strip, escape_html)
            escape_html = false
          else
            value = value[1..-1].strip
          end
        elsif contains_interpolation?(value)
          value = unescape_interpolation(value, escape_html)
          parse = true
          escape_html = false
        end
      else
        if contains_interpolation?(value)
          value = unescape_interpolation(value, escape_html)
          parse = true
          escape_html = false
        end
      end

      attributes = Parser.parse_class_and_id(attributes)
      dynamic_attributes = DynamicAttributes.new

      if attributes_hashes[:new]
        static_attributes, attributes_hash = attributes_hashes[:new]
        AttributeBuilder.merge_attributes!(attributes, static_attributes) if static_attributes
        dynamic_attributes.new = attributes_hash
      end

      if attributes_hashes[:old]
        static_attributes = parse_static_hash(attributes_hashes[:old])
        AttributeBuilder.merge_attributes!(attributes, static_attributes) if static_attributes
        dynamic_attributes.old = attributes_hashes[:old] unless static_attributes || @options.suppress_eval
      end

      raise SyntaxError.new(Error.message(:illegal_nesting_self_closing), @next_line.index) if block_opened? && self_closing
      raise SyntaxError.new(Error.message(:no_ruby_code, action), last_line - 1) if parse && value.empty?
      raise SyntaxError.new(Error.message(:self_closing_content), last_line - 1) if self_closing && !value.empty?

      if block_opened? && !value.empty? && !is_ruby_multiline?(value)
        raise SyntaxError.new(Error.message(:illegal_nesting_line, tag_name), @next_line.index)
      end

      self_closing ||= !!(!block_opened? && value.empty? && @options.autoclose.any? {|t| t === tag_name})
      value = nil if value.empty? && (block_opened? || self_closing)
      line.text = value
      line = handle_ruby_multiline(line) if parse

      ParseNode.new(:tag, line.index + 1, :name => tag_name, :attributes => attributes,
        :dynamic_attributes => dynamic_attributes, :self_closing => self_closing,
        :nuke_inner_whitespace => nuke_inner_whitespace,
        :nuke_outer_whitespace => nuke_outer_whitespace, :object_ref => object_ref,
        :escape_html => escape_html, :preserve_tag => preserve_tag,
        :preserve_script => preserve_script, :parse => parse, :value => line.text)
    end

    # Renders a line that creates an XHTML tag and has an implicit div because of
    # `.` or `#`.
    def div(line)
      line.text = "%div#{line.text}"
      tag(line)
    end

    # Renders an XHTML comment.
    def comment(text)
      if text[0..1] == '!['
        revealed = true
        text = text[1..-1]
      else
        revealed = false
      end

      conditional, text = balance(text, ?[, ?]) if text[0] == ?[
      text.strip!

      if contains_interpolation?(text)
        parse = true
        text = unescape_interpolation(text)
      else
        parse = false
      end

      if block_opened? && !text.empty?
        raise SyntaxError.new(Haml::Error.message(:illegal_nesting_content), @next_line.index)
      end

      ParseNode.new(:comment, @line.index + 1, :conditional => conditional, :text => text, :revealed => revealed, :parse => parse)
    end

    # Renders an XHTML doctype or XML shebang.
    def doctype(text)
      raise SyntaxError.new(Error.message(:illegal_nesting_header), @next_line.index) if block_opened?
      version, type, encoding = text[3..-1].strip.downcase.scan(DOCTYPE_REGEX)[0]
      ParseNode.new(:doctype, @line.index + 1, :version => version, :type => type, :encoding => encoding)
    end

    def filter(name)
      raise Error.new(Error.message(:invalid_filter_name, name)) unless name =~ /^\w+$/

      if filter_opened?
        @flat = true
        @filter_buffer = String.new
        # If we don't know the indentation by now, it'll be set in Line#tabs
        @flat_spaces = @indentation * (@template_tabs+1) if @indentation
      end

      ParseNode.new(:filter, @line.index + 1, :name => name, :text => @filter_buffer)
    end

    def close
      node, @parent = @parent, @parent.parent
      @template_tabs -= 1
      send("close_#{node.type}", node) if respond_to?("close_#{node.type}", :include_private)
    end

    def close_filter(_)
      close_flat_section
    end

    def close_haml_comment(_)
      close_flat_section
    end

    def close_flat_section
      @flat = false
      @flat_spaces = nil
      @filter_buffer = nil
    end

    def close_silent_script(node)
      @script_level_stack.pop if ["if", "case", "unless"].include? node.value[:keyword]

      # Post-process case statements to normalize the nesting of "when" clauses
      return unless node.value[:keyword] == "case"
      return unless (first = node.children.first)
      return unless first.type == :silent_script && first.value[:keyword] == "when"
      return if first.children.empty?
      # If the case node has a "when" child with children, it's the
      # only child. Then we want to put everything nested beneath it
      # beneath the case itself (just like "if").
      node.children = [first, *first.children]
      first.children = []
    end

    alias :close_script :close_silent_script

    # This is a class method so it can be accessed from {Haml::Helpers}.
    #
    # Iterates through the classes and ids supplied through `.`
    # and `#` syntax, and returns a hash with them as attributes,
    # that can then be merged with another attributes hash.
    def self.parse_class_and_id(list)
      attributes = {}
      return attributes if list.empty?

      list.scan(/([#.])([-:_a-zA-Z0-9\@]+)/) do |type, property|
        case type
        when '.'
          if attributes[CLASS_KEY]
            attributes[CLASS_KEY] += " "
          else
            attributes[CLASS_KEY] = ""
          end
          attributes[CLASS_KEY] += property
        when '#'; attributes[ID_KEY] = property
        end
      end
      attributes
    end

    # This method doesn't use Haml::AttributeParser because currently it depends on Ripper and Rubinius doesn't provide it.
    # Ideally this logic should be placed in Haml::AttributeParser instead of here and this method should use it.
    #
    # @param  [String] text - Hash literal or text inside old attributes
    # @return [Hash,nil] - Return nil if text is not static Hash literal
    def parse_static_hash(text)
      attributes = {}
      return attributes if text.empty?

      text = text[1...-1] # strip brackets
      scanner = StringScanner.new(text)
      scanner.scan(/\s+/)
      until scanner.eos?
        return unless (key = scanner.scan(LITERAL_VALUE_REGEX))
        return unless scanner.scan(/\s*=>\s*/)
        return unless (value = scanner.scan(LITERAL_VALUE_REGEX))
        return unless scanner.scan(/\s*(?:,|$)\s*/)
        attributes[eval(key).to_s] = eval(value).to_s
      end
      attributes
    end

    # Parses a line into tag_name, attributes, attributes_hash, object_ref, action, value
    def parse_tag(text)
      match = text.scan(/%([-:\w]+)([-:\w.#\@]*)(.+)?/)[0]
      raise SyntaxError.new(Error.message(:invalid_tag, text)) unless match

      tag_name, attributes, rest = match

      if !attributes.empty? && (attributes =~ /[.#](\.|#|\z)/)
        raise SyntaxError.new(Error.message(:illegal_element))
      end

      new_attributes_hash = old_attributes_hash = last_line = nil
      object_ref = :nil
      attributes_hashes = {}
      while rest && !rest.empty?
        case rest[0]
        when ?{
          break if old_attributes_hash
          old_attributes_hash, rest, last_line = parse_old_attributes(rest)
          attributes_hashes[:old] = old_attributes_hash
        when ?(
          break if new_attributes_hash
          new_attributes_hash, rest, last_line = parse_new_attributes(rest)
          attributes_hashes[:new] = new_attributes_hash
        when ?[
          break unless object_ref == :nil
          object_ref, rest = balance(rest, ?[, ?])
        else; break
        end
      end

      if rest && !rest.empty?
        nuke_whitespace, action, value = rest.scan(/(<>|><|[><])?([=\/\~&!])?(.*)?/)[0]
        if nuke_whitespace
          nuke_outer_whitespace = nuke_whitespace.include? '>'
          nuke_inner_whitespace = nuke_whitespace.include? '<'
        end
      end

      if @options.remove_whitespace
        nuke_outer_whitespace = true
        nuke_inner_whitespace = true
      end

      if value.nil?
        value = ''
      else
        value.strip!
      end
      [tag_name, attributes, attributes_hashes, object_ref, nuke_outer_whitespace,
       nuke_inner_whitespace, action, value, last_line || @line.index + 1]
    end

    # @return [String] attributes_hash - Hash literal starting with `{` and ending with `}`
    # @return [String] rest
    # @return [Integer] last_line
    def parse_old_attributes(text)
      last_line = @line.index + 1

      begin
        # Old attributes often look like a valid Hash literal, but it sometimes allow code like
        # `{ hash, foo: bar }`, which is compiled to `_hamlout.attributes({}, nil, hash, foo: bar)`.
        #
        # To scan such code correctly, this scans `a( hash, foo: bar }` instead, stops when there is
        # 1 more :on_embexpr_end (the last '}') than :on_embexpr_beg, and resurrects '{' afterwards.
        balanced, rest = balance_tokens(text.sub(?{, METHOD_CALL_PREFIX), :on_embexpr_beg, :on_embexpr_end, count: 1)
        attributes_hash = balanced.sub(METHOD_CALL_PREFIX, ?{)
      rescue SyntaxError => e
        if e.message == Error.message(:unbalanced_brackets) && !@template.empty?
          text << "\n#{@next_line.text}"
          last_line += 1
          next_line
          retry
        end

        raise e
      end

      return attributes_hash, rest, last_line
    end

    # @return [Array<Hash,String,nil>] - [static_attributes (Hash), dynamic_attributes (nil or String starting with `{` and ending with `}`)]
    # @return [String] rest
    # @return [Integer] last_line
    def parse_new_attributes(text)
      scanner = StringScanner.new(text)
      last_line = @line.index + 1
      attributes = {}

      scanner.scan(/\(\s*/)
      loop do
        name, value = parse_new_attribute(scanner)
        break if name.nil?

        if name == false
          scanned = Haml::Util.balance(text, ?(, ?))
          text = scanned ? scanned.first : text
          raise Haml::SyntaxError.new(Error.message(:invalid_attribute_list, text.inspect), last_line - 1)
        end
        attributes[name] = value
        scanner.scan(/\s*/)

        if scanner.eos?
          text << " #{@next_line.text}"
          last_line += 1
          next_line
          scanner.scan(/\s*/)
        end
      end

      static_attributes = {}
      dynamic_attributes = "{".dup
      attributes.each do |name, (type, val)|
        if type == :static
          static_attributes[name] = val
        else
          dynamic_attributes << "#{inspect_obj(name)} => #{val},"
        end
      end
      dynamic_attributes << "}"
      dynamic_attributes = nil if dynamic_attributes == "{}"

      return [static_attributes, dynamic_attributes], scanner.rest, last_line
    end

    def parse_new_attribute(scanner)
      unless (name = scanner.scan(/[-:\w]+/))
        return if scanner.scan(/\)/)
        return false
      end

      scanner.scan(/\s*/)
      return name, [:static, true] unless scanner.scan(/=/) #/end

      scanner.scan(/\s*/)
      unless (quote = scanner.scan(/["']/))
        return false unless (var = scanner.scan(/(@@?|\$)?\w+/))
        return name, [:dynamic, var]
      end

      re = /((?:\\.|\#(?!\{)|[^#{quote}\\#])*)(#{quote}|#\{)/
      content = []
      loop do
        return false unless scanner.scan(re)
        content << [:str, scanner[1].gsub(/\\(.)/, '\1')]
        break if scanner[2] == quote
        content << [:ruby, balance(scanner, ?{, ?}, 1).first[0...-1]]
      end

      return name, [:static, content.first[1]] if content.size == 1
      return name, [:dynamic,
        %!"#{content.each_with_object(''.dup) {|(t, v), s| s << (t == :str ? inspect_obj(v)[1...-1] : "\#{#{v}}")}}"!]
    end

    def next_line
      line = @template.shift || raise(StopIteration)

      # `flat?' here is a little outdated,
      # so we have to manually check if either the previous or current line
      # closes the flat block, as well as whether a new block is opened.
      line_defined = instance_variable_defined?(:@line)
      @line.tabs if line_defined
      unless (flat? && !closes_flat?(line) && !closes_flat?(@line)) ||
          (line_defined && @line.text[0] == ?: && line.full =~ %r[^#{@line.full[/^\s+/]}\s])
        return next_line if line.text.empty?

        handle_multiline(line)
      end

      @next_line = line
    end

    def closes_flat?(line)
      line && !line.text.empty? && line.full !~ /^#{@flat_spaces}/
    end

    def handle_multiline(line)
      return unless is_multiline?(line.text)
      line.text.slice!(-1)
      loop do
        new_line = @template.first
        break if new_line.eod?
        next @template.shift if new_line.text.strip.empty?
        break unless is_multiline?(new_line.text.strip)
        line.text << new_line.text.strip[0...-1]
        @template.shift
      end
    end

    # Checks whether or not `line` is in a multiline sequence.
    def is_multiline?(text)
      text && text.length > 1 && text[-1] == MULTILINE_CHAR_VALUE && text[-2] == ?\s && text !~ BLOCK_WITH_SPACES
    end

    def handle_ruby_multiline(line)
      line.text.rstrip!
      return line unless is_ruby_multiline?(line.text)
      begin
        # Use already fetched @next_line in the first loop. Otherwise, fetch next
        new_line = new_line.nil? ? @next_line : @template.shift
        break if new_line.eod?
        next if new_line.text.empty?
        line.text << " #{new_line.text.rstrip}"
      end while is_ruby_multiline?(new_line.text)
      next_line
      line
    end

    # `text' is a Ruby multiline block if it:
    # - ends with a comma
    # - but not "?," which is a character literal
    #   (however, "x?," is a method call and not a literal)
    # - and not "?\," which is a character literal
    def is_ruby_multiline?(text)
      text && text.length > 1 && text[-1] == ?, &&
        !((text[-3, 2] =~ /\W\?/) || text[-3, 2] == "?\\")
    end

    def balance(*args)
      Haml::Util.balance(*args) or raise(SyntaxError.new(Error.message(:unbalanced_brackets)))
    end

    # Unlike #balance, this balances Ripper tokens to balance something like `{ a: "}" }` correctly.
    def balance_tokens(buf, start, finish, count: 0)
      text = ''.dup
      Ripper.lex(buf).each do |_, token, str|
        text << str
        case token
        when start
          count += 1
        when finish
          count -= 1
        end

        if count == 0
          return text, buf.sub(text, '')
        end
      end
      raise SyntaxError.new(Error.message(:unbalanced_brackets))
    end

    def block_opened?
      @next_line.tabs > @line.tabs
    end

    # Same semantics as block_opened?, except that block_opened? uses Line#tabs,
    # which doesn't interact well with filter lines
    def filter_opened?
      @next_line.full =~ (@indentation ? /^#{@indentation * (@template_tabs + 1)}/ : /^\s/)
    end

    def flat?
      @flat
    end
  end
end
