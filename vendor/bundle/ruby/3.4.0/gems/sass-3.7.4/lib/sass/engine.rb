require 'set'
require 'digest/sha1'
require 'sass/cache_stores'
require 'sass/deprecation'
require 'sass/source/position'
require 'sass/source/range'
require 'sass/source/map'
require 'sass/tree/node'
require 'sass/tree/root_node'
require 'sass/tree/rule_node'
require 'sass/tree/comment_node'
require 'sass/tree/prop_node'
require 'sass/tree/directive_node'
require 'sass/tree/media_node'
require 'sass/tree/supports_node'
require 'sass/tree/css_import_node'
require 'sass/tree/variable_node'
require 'sass/tree/mixin_def_node'
require 'sass/tree/mixin_node'
require 'sass/tree/trace_node'
require 'sass/tree/content_node'
require 'sass/tree/function_node'
require 'sass/tree/return_node'
require 'sass/tree/extend_node'
require 'sass/tree/if_node'
require 'sass/tree/while_node'
require 'sass/tree/for_node'
require 'sass/tree/each_node'
require 'sass/tree/debug_node'
require 'sass/tree/warn_node'
require 'sass/tree/import_node'
require 'sass/tree/charset_node'
require 'sass/tree/at_root_node'
require 'sass/tree/keyframe_rule_node'
require 'sass/tree/error_node'
require 'sass/tree/visitors/base'
require 'sass/tree/visitors/perform'
require 'sass/tree/visitors/cssize'
require 'sass/tree/visitors/extend'
require 'sass/tree/visitors/convert'
require 'sass/tree/visitors/to_css'
require 'sass/tree/visitors/deep_copy'
require 'sass/tree/visitors/set_options'
require 'sass/tree/visitors/check_nesting'
require 'sass/selector'
require 'sass/environment'
require 'sass/script'
require 'sass/scss'
require 'sass/stack'
require 'sass/error'
require 'sass/importers'
require 'sass/shared'
require 'sass/media'
require 'sass/supports'

module Sass
  # A Sass mixin or function.
  #
  # `name`: `String`
  # : The name of the mixin/function.
  #
  # `args`: `Array<(Script::Tree::Node, Script::Tree::Node)>`
  # : The arguments for the mixin/function.
  #   Each element is a tuple containing the variable node of the argument
  #   and the parse tree for the default value of the argument.
  #
  # `splat`: `Script::Tree::Node?`
  # : The variable node of the splat argument for this callable, or null.
  #
  # `environment`: {Sass::Environment}
  # : The environment in which the mixin/function was defined.
  #   This is captured so that the mixin/function can have access
  #   to local variables defined in its scope.
  #
  # `tree`: `Array<Tree::Node>`
  # : The parse tree for the mixin/function.
  #
  # `has_content`: `Boolean`
  # : Whether the callable accepts a content block.
  #
  # `type`: `String`
  # : The user-friendly name of the type of the callable.
  #
  # `origin`: `Symbol`
  # : From whence comes the callable: `:stylesheet`, `:builtin`, `:css`
  #   A callable with an origin of `:stylesheet` was defined in the stylesheet itself.
  #   A callable with an origin of `:builtin` was defined in ruby.
  #   A callable (function) with an origin of `:css` returns a function call with arguments to CSS.
  Callable = Struct.new(:name, :args, :splat, :environment, :tree, :has_content, :type, :origin)

  # This class handles the parsing and compilation of the Sass template.
  # Example usage:
  #
  #     template = File.read('stylesheets/sassy.sass')
  #     sass_engine = Sass::Engine.new(template)
  #     output = sass_engine.render
  #     puts output
  class Engine
    @@old_property_deprecation = Deprecation.new

    # A line of Sass code.
    #
    # `text`: `String`
    # : The text in the line, without any whitespace at the beginning or end.
    #
    # `tabs`: `Integer`
    # : The level of indentation of the line.
    #
    # `index`: `Integer`
    # : The line number in the original document.
    #
    # `offset`: `Integer`
    # : The number of bytes in on the line that the text begins.
    #   This ends up being the number of bytes of leading whitespace.
    #
    # `filename`: `String`
    # : The name of the file in which this line appeared.
    #
    # `children`: `Array<Line>`
    # : The lines nested below this one.
    #
    # `comment_tab_str`: `String?`
    # : The prefix indentation for this comment, if it is a comment.
    class Line < Struct.new(:text, :tabs, :index, :offset, :filename, :children, :comment_tab_str)
      def comment?
        text[0] == COMMENT_CHAR && (text[1] == SASS_COMMENT_CHAR || text[1] == CSS_COMMENT_CHAR)
      end
    end

    # The character that begins a CSS property.
    PROPERTY_CHAR  = ?:

    # The character that designates the beginning of a comment,
    # either Sass or CSS.
    COMMENT_CHAR = ?/

    # The character that follows the general COMMENT_CHAR and designates a Sass comment,
    # which is not output as a CSS comment.
    SASS_COMMENT_CHAR = ?/

    # The character that indicates that a comment allows interpolation
    # and should be preserved even in `:compressed` mode.
    SASS_LOUD_COMMENT_CHAR = ?!

    # The character that follows the general COMMENT_CHAR and designates a CSS comment,
    # which is embedded in the CSS document.
    CSS_COMMENT_CHAR = ?*

    # The character used to denote a compiler directive.
    DIRECTIVE_CHAR = ?@

    # Designates a non-parsed rule.
    ESCAPE_CHAR    = ?\\

    # Designates block as mixin definition rather than CSS rules to output
    MIXIN_DEFINITION_CHAR = ?=

    # Includes named mixin declared using MIXIN_DEFINITION_CHAR
    MIXIN_INCLUDE_CHAR    = ?+

    # The regex that matches and extracts data from
    # properties of the form `:name prop`.
    PROPERTY_OLD = /^:([^\s=:"]+)\s*(?:\s+|$)(.*)/

    # The default options for Sass::Engine.
    # @api public
    DEFAULT_OPTIONS = {
      :style => :nested,
      :load_paths => [],
      :cache => true,
      :cache_location => './.sass-cache',
      :syntax => :sass,
      :filesystem_importer => Sass::Importers::Filesystem
    }.freeze

    # Converts a Sass options hash into a standard form, filling in
    # default values and resolving aliases.
    #
    # @param options [{Symbol => Object}] The options hash;
    #   see {file:SASS_REFERENCE.md#Options the Sass options documentation}
    # @return [{Symbol => Object}] The normalized options hash.
    # @private
    def self.normalize_options(options)
      options = DEFAULT_OPTIONS.merge(options.reject {|_k, v| v.nil?})

      # If the `:filename` option is passed in without an importer,
      # assume it's using the default filesystem importer.
      options[:importer] ||= options[:filesystem_importer].new(".") if options[:filename]

      # Tracks the original filename of the top-level Sass file
      options[:original_filename] ||= options[:filename]

      options[:cache_store] ||= Sass::CacheStores::Chain.new(
        Sass::CacheStores::Memory.new, Sass::CacheStores::Filesystem.new(options[:cache_location]))
      # Support both, because the docs said one and the other actually worked
      # for quite a long time.
      options[:line_comments] ||= options[:line_numbers]

      options[:load_paths] = (options[:load_paths] + Sass.load_paths).map do |p|
        next p unless p.is_a?(String) || (defined?(Pathname) && p.is_a?(Pathname))
        options[:filesystem_importer].new(p.to_s)
      end

      # Remove any deprecated importers if the location is imported explicitly
      options[:load_paths].reject! do |importer|
        importer.is_a?(Sass::Importers::DeprecatedPath) &&
          options[:load_paths].find do |other_importer|
            other_importer.is_a?(Sass::Importers::Filesystem) &&
              other_importer != importer &&
              other_importer.root == importer.root
          end
      end

      # Backwards compatibility
      options[:property_syntax] ||= options[:attribute_syntax]
      case options[:property_syntax]
      when :alternate; options[:property_syntax] = :new
      when :normal; options[:property_syntax] = :old
      end
      options[:sourcemap] = :auto if options[:sourcemap] == true
      options[:sourcemap] = :none if options[:sourcemap] == false

      options
    end

    # Returns the {Sass::Engine} for the given file.
    # This is preferable to Sass::Engine.new when reading from a file
    # because it properly sets up the Engine's metadata,
    # enables parse-tree caching,
    # and infers the syntax from the filename.
    #
    # @param filename [String] The path to the Sass or SCSS file
    # @param options [{Symbol => Object}] The options hash;
    #   See {file:SASS_REFERENCE.md#Options the Sass options documentation}.
    # @return [Sass::Engine] The Engine for the given Sass or SCSS file.
    # @raise [Sass::SyntaxError] if there's an error in the document.
    def self.for_file(filename, options)
      had_syntax = options[:syntax]

      if had_syntax
        # Use what was explicitly specified
      elsif filename =~ /\.scss$/
        options.merge!(:syntax => :scss)
      elsif filename =~ /\.sass$/
        options.merge!(:syntax => :sass)
      end

      Sass::Engine.new(File.read(filename), options.merge(:filename => filename))
    end

    # The options for the Sass engine.
    # See {file:SASS_REFERENCE.md#Options the Sass options documentation}.
    #
    # @return [{Symbol => Object}]
    attr_reader :options

    # Creates a new Engine. Note that Engine should only be used directly
    # when compiling in-memory Sass code.
    # If you're compiling a single Sass file from the filesystem,
    # use \{Sass::Engine.for\_file}.
    # If you're compiling multiple files from the filesystem,
    # use {Sass::Plugin}.
    #
    # @param template [String] The Sass template.
    #   This template can be encoded using any encoding
    #   that can be converted to Unicode.
    #   If the template contains an `@charset` declaration,
    #   that overrides the Ruby encoding
    #   (see {file:SASS_REFERENCE.md#Encodings the encoding documentation})
    # @param options [{Symbol => Object}] An options hash.
    #   See {file:SASS_REFERENCE.md#Options the Sass options documentation}.
    # @see {Sass::Engine.for_file}
    # @see {Sass::Plugin}
    def initialize(template, options = {})
      @options = self.class.normalize_options(options)
      @template = template
      @checked_encoding = false
      @filename = nil
      @line = nil
    end

    # Render the template to CSS.
    #
    # @return [String] The CSS
    # @raise [Sass::SyntaxError] if there's an error in the document
    # @raise [Encoding::UndefinedConversionError] if the source encoding
    #   cannot be converted to UTF-8
    # @raise [ArgumentError] if the document uses an unknown encoding with `@charset`
    def render
      return _to_tree.render unless @options[:quiet]
      Sass::Util.silence_sass_warnings {_to_tree.render}
    end

    # Render the template to CSS and return the source map.
    #
    # @param sourcemap_uri [String] The sourcemap URI to use in the
    #   `@sourceMappingURL` comment. If this is relative, it should be relative
    #   to the location of the CSS file.
    # @return [(String, Sass::Source::Map)] The rendered CSS and the associated
    #   source map
    # @raise [Sass::SyntaxError] if there's an error in the document, or if the
    #   public URL for this document couldn't be determined.
    # @raise [Encoding::UndefinedConversionError] if the source encoding
    #   cannot be converted to UTF-8
    # @raise [ArgumentError] if the document uses an unknown encoding with `@charset`
    def render_with_sourcemap(sourcemap_uri)
      return _render_with_sourcemap(sourcemap_uri) unless @options[:quiet]
      Sass::Util.silence_sass_warnings {_render_with_sourcemap(sourcemap_uri)}
    end

    alias_method :to_css, :render

    # Parses the document into its parse tree. Memoized.
    #
    # @return [Sass::Tree::Node] The root of the parse tree.
    # @raise [Sass::SyntaxError] if there's an error in the document
    def to_tree
      @tree ||= if @options[:quiet]
                  Sass::Util.silence_sass_warnings {_to_tree}
                else
                  _to_tree
                end
    end

    # Returns the original encoding of the document.
    #
    # @return [Encoding, nil]
    # @raise [Encoding::UndefinedConversionError] if the source encoding
    #   cannot be converted to UTF-8
    # @raise [ArgumentError] if the document uses an unknown encoding with `@charset`
    def source_encoding
      check_encoding!
      @source_encoding
    end

    # Gets a set of all the documents
    # that are (transitive) dependencies of this document,
    # not including the document itself.
    #
    # @return [[Sass::Engine]] The dependency documents.
    def dependencies
      _dependencies(Set.new, engines = Set.new)
      Sass::Util.array_minus(engines, [self])
    end

    # Helper for \{#dependencies}.
    #
    # @private
    def _dependencies(seen, engines)
      key = [@options[:filename], @options[:importer]]
      return if seen.include?(key)
      seen << key
      engines << self
      to_tree.grep(Tree::ImportNode) do |n|
        next if n.css_import?
        n.imported_file._dependencies(seen, engines)
      end
    end

    private

    def _render_with_sourcemap(sourcemap_uri)
      filename = @options[:filename]
      importer = @options[:importer]
      sourcemap_dir = @options[:sourcemap_filename] &&
        File.dirname(File.expand_path(@options[:sourcemap_filename]))
      if filename.nil?
        raise Sass::SyntaxError.new(<<ERR)
Error generating source map: couldn't determine public URL for the source stylesheet.
  No filename is available so there's nothing for the source map to link to.
ERR
      elsif importer.nil?
        raise Sass::SyntaxError.new(<<ERR)
Error generating source map: couldn't determine public URL for "#{filename}".
  Without a public URL, there's nothing for the source map to link to.
  An importer was not set for this file.
ERR
      elsif Sass::Util.silence_sass_warnings do
              sourcemap_dir = nil if @options[:sourcemap] == :file
              importer.public_url(filename, sourcemap_dir).nil?
            end
        raise Sass::SyntaxError.new(<<ERR)
Error generating source map: couldn't determine public URL for "#{filename}".
  Without a public URL, there's nothing for the source map to link to.
  Custom importers should define the #public_url method.
ERR
      end

      rendered, sourcemap = _to_tree.render_with_sourcemap
      compressed = @options[:style] == :compressed
      rendered << "\n" if rendered[-1] != ?\n
      rendered << "\n" unless compressed
      rendered << "/*# sourceMappingURL="
      rendered << URI::DEFAULT_PARSER.escape(sourcemap_uri)
      rendered << " */\n"
      return rendered, sourcemap
    end

    def _to_tree
      check_encoding!

      if (@options[:cache] || @options[:read_cache]) &&
          @options[:filename] && @options[:importer]
        key = sassc_key
        sha = Digest::SHA1.hexdigest(@template)

        if (root = @options[:cache_store].retrieve(key, sha))
          root.options = @options
          return root
        end
      end

      if @options[:syntax] == :scss
        root = Sass::SCSS::Parser.new(@template, @options[:filename], @options[:importer]).parse
      else
        root = Tree::RootNode.new(@template)
        append_children(root, tree(tabulate(@template)).first, true)
      end

      root.options = @options
      if @options[:cache] && key && sha
        begin
          old_options = root.options
          root.options = {}
          @options[:cache_store].store(key, sha, root)
        ensure
          root.options = old_options
        end
      end
      root
    rescue SyntaxError => e
      e.modify_backtrace(:filename => @options[:filename], :line => @line)
      e.sass_template = @template
      raise e
    end

    def sassc_key
      @options[:cache_store].key(*@options[:importer].key(@options[:filename], @options))
    end

    def check_encoding!
      return if @checked_encoding
      @checked_encoding = true
      @template, @source_encoding = Sass::Util.check_sass_encoding(@template)
    end

    def tabulate(string)
      tab_str = nil
      comment_tab_str = nil
      first = true
      lines = []
      string.scan(/^[^\n]*?$/).each_with_index do |line, index|
        index += (@options[:line] || 1)
        if line.strip.empty?
          lines.last.text << "\n" if lines.last && lines.last.comment?
          next
        end

        line_tab_str = line[/^\s*/]
        unless line_tab_str.empty?
          if tab_str.nil?
            comment_tab_str ||= line_tab_str
            next if try_comment(line, lines.last, "", comment_tab_str, index)
            comment_tab_str = nil
          end

          tab_str ||= line_tab_str

          raise SyntaxError.new("Indenting at the beginning of the document is illegal.",
            :line => index) if first

          raise SyntaxError.new("Indentation can't use both tabs and spaces.",
            :line => index) if tab_str.include?(?\s) && tab_str.include?(?\t)
        end
        first &&= !tab_str.nil?
        if tab_str.nil?
          lines << Line.new(line.strip, 0, index, 0, @options[:filename], [])
          next
        end

        comment_tab_str ||= line_tab_str
        if try_comment(line, lines.last, tab_str * lines.last.tabs, comment_tab_str, index)
          next
        else
          comment_tab_str = nil
        end

        line_tabs = line_tab_str.scan(tab_str).size
        if tab_str * line_tabs != line_tab_str
          message = <<END.strip.tr("\n", ' ')
Inconsistent indentation: #{Sass::Shared.human_indentation line_tab_str, true} used for indentation,
but the rest of the document was indented using #{Sass::Shared.human_indentation tab_str}.
END
          raise SyntaxError.new(message, :line => index)
        end

        lines << Line.new(line.strip, line_tabs, index, line_tab_str.size, @options[:filename], [])
      end
      lines
    end

    def try_comment(line, last, tab_str, comment_tab_str, index)
      return unless last && last.comment?
      # Nested comment stuff must be at least one whitespace char deeper
      # than the normal indentation
      return unless line =~ /^#{tab_str}\s/
      unless line =~ /^(?:#{comment_tab_str})(.*)$/
        raise SyntaxError.new(<<MSG.strip.tr("\n", " "), :line => index)
Inconsistent indentation:
previous line was indented by #{Sass::Shared.human_indentation comment_tab_str},
but this line was indented by #{Sass::Shared.human_indentation line[/^\s*/]}.
MSG
      end

      last.comment_tab_str ||= comment_tab_str
      last.text << "\n" << line
      true
    end

    def tree(arr, i = 0)
      return [], i if arr[i].nil?

      base = arr[i].tabs
      nodes = []
      while (line = arr[i]) && line.tabs >= base
        if line.tabs > base
          nodes.last.children, i = tree(arr, i)
        else
          nodes << line
          i += 1
        end
      end
      return nodes, i
    end

    def build_tree(parent, line, root = false)
      @line = line.index
      @offset = line.offset
      node_or_nodes = parse_line(parent, line, root)

      Array(node_or_nodes).each do |node|
        # Node is a symbol if it's non-outputting, like a variable assignment
        next unless node.is_a? Tree::Node

        node.line = line.index
        node.filename = line.filename

        append_children(node, line.children, false)
      end

      node_or_nodes
    end

    def append_children(parent, children, root)
      continued_rule = nil
      continued_comment = nil
      children.each do |line|
        child = build_tree(parent, line, root)

        if child.is_a?(Tree::RuleNode)
          if child.continued? && child.children.empty?
            if continued_rule
              continued_rule.add_rules child
            else
              continued_rule = child
            end
            next
          elsif continued_rule
            continued_rule.add_rules child
            continued_rule.children = child.children
            continued_rule, child = nil, continued_rule
          end
        elsif continued_rule
          continued_rule = nil
        end

        if child.is_a?(Tree::CommentNode) && child.type == :silent
          if continued_comment &&
              child.line == continued_comment.line +
              continued_comment.lines + 1
            continued_comment.value.last.sub!(%r{ \*/\Z}, '')
            child.value.first.gsub!(%r{\A/\*}, ' *')
            continued_comment.value += ["\n"] + child.value
            next
          end

          continued_comment = child
        end

        check_for_no_children(child)
        validate_and_append_child(parent, child, line, root)
      end

      parent
    end

    def validate_and_append_child(parent, child, line, root)
      case child
      when Array
        child.each {|c| validate_and_append_child(parent, c, line, root)}
      when Tree::Node
        parent << child
      end
    end

    def check_for_no_children(node)
      return unless node.is_a?(Tree::RuleNode) && node.children.empty?
      Sass::Util.sass_warn(<<WARNING.strip)
WARNING on line #{node.line}#{" of #{node.filename}" if node.filename}:
This selector doesn't have any properties and will not be rendered.
WARNING
    end

    def parse_line(parent, line, root)
      case line.text[0]
      when PROPERTY_CHAR
        if line.text[1] == PROPERTY_CHAR ||
            (@options[:property_syntax] == :new &&
             line.text =~ PROPERTY_OLD && $2.empty?)
          # Support CSS3-style pseudo-elements,
          # which begin with ::,
          # as well as pseudo-classes
          # if we're using the new property syntax
          Tree::RuleNode.new(parse_interp(line.text), full_line_range(line))
        else
          name_start_offset = line.offset + 1 # +1 for the leading ':'
          name, value = line.text.scan(PROPERTY_OLD)[0]
          raise SyntaxError.new("Invalid property: \"#{line.text}\".",
            :line => @line) if name.nil? || value.nil?

          @@old_property_deprecation.warn(@options[:filename], @line, <<WARNING)
Old-style properties like "#{line.text}" are deprecated and will be an error in future versions of Sass.
Use "#{name}: #{value}" instead.
WARNING

          value_start_offset = name_end_offset = name_start_offset + name.length
          unless value.empty?
            # +1 and -1 both compensate for the leading ':', which is part of line.text
            value_start_offset = name_start_offset + line.text.index(value, name.length + 1) - 1
          end

          property = parse_property(name, parse_interp(name), value, :old, line, value_start_offset)
          property.name_source_range = Sass::Source::Range.new(
            Sass::Source::Position.new(@line, to_parser_offset(name_start_offset)),
            Sass::Source::Position.new(@line, to_parser_offset(name_end_offset)),
            @options[:filename], @options[:importer])
          property
        end
      when ?$
        parse_variable(line)
      when COMMENT_CHAR
        parse_comment(line)
      when DIRECTIVE_CHAR
        parse_directive(parent, line, root)
      when ESCAPE_CHAR
        Tree::RuleNode.new(parse_interp(line.text[1..-1]), full_line_range(line))
      when MIXIN_DEFINITION_CHAR
        parse_mixin_definition(line)
      when MIXIN_INCLUDE_CHAR
        if line.text[1].nil? || line.text[1] == ?\s
          Tree::RuleNode.new(parse_interp(line.text), full_line_range(line))
        else
          parse_mixin_include(line, root)
        end
      else
        parse_property_or_rule(line)
      end
    end

    def parse_property_or_rule(line)
      scanner = Sass::Util::MultibyteStringScanner.new(line.text)
      hack_char = scanner.scan(/[:\*\.]|\#(?!\{)/)
      offset = line.offset
      offset += hack_char.length if hack_char
      parser = Sass::SCSS::Parser.new(scanner,
        @options[:filename], @options[:importer],
        @line, to_parser_offset(offset))

      unless (res = parser.parse_interp_ident)
        parsed = parse_interp(line.text, line.offset)
        return Tree::RuleNode.new(parsed, full_line_range(line))
      end

      ident_range = Sass::Source::Range.new(
        Sass::Source::Position.new(@line, to_parser_offset(line.offset)),
        Sass::Source::Position.new(@line, parser.offset),
        @options[:filename], @options[:importer])
      offset = parser.offset - 1
      res.unshift(hack_char) if hack_char

      # Handle comments after a property name but before the colon.
      if (comment = scanner.scan(Sass::SCSS::RX::COMMENT))
        res << comment
        offset += comment.length
      end

      name = line.text[0...scanner.pos]
      could_be_property =
        if name.start_with?('--')
          (scanned = scanner.scan(/\s*:/))
        else
          (scanned = scanner.scan(/\s*:(?:\s+|$)/))
        end

      if could_be_property # test for a property
        offset += scanned.length
        property = parse_property(name, res, scanner.rest, :new, line, offset)
        property.name_source_range = ident_range
        property
      else
        res.pop if comment

        if (trailing = (scanner.scan(/\s*#{Sass::SCSS::RX::COMMENT}/) ||
                        scanner.scan(/\s*#{Sass::SCSS::RX::SINGLE_LINE_COMMENT}/)))
          trailing.strip!
        end
        interp_parsed = parse_interp(scanner.rest)
        selector_range = Sass::Source::Range.new(
          ident_range.start_pos,
          Sass::Source::Position.new(@line, to_parser_offset(line.offset) + line.text.length),
          @options[:filename], @options[:importer])
        rule = Tree::RuleNode.new(res + interp_parsed, selector_range)
        rule << Tree::CommentNode.new([trailing], :silent) if trailing
        rule
      end
    end

    def parse_property(name, parsed_name, value, prop, line, start_offset)

      if name.start_with?('--')
        unless line.children.empty?
          raise SyntaxError.new("Illegal nesting: Nothing may be nested beneath custom properties.",
            :line => @line + 1)
        end

        parser = Sass::SCSS::Parser.new(value,
          @options[:filename], @options[:importer],
          @line, to_parser_offset(@offset))
        parsed_value = parser.parse_declaration_value
        end_offset = start_offset + value.length
      elsif value.strip.empty?
        parsed_value = [Sass::Script::Tree::Literal.new(Sass::Script::Value::String.new(""))]
        end_offset = start_offset
      else
        expr = parse_script(value, :offset => to_parser_offset(start_offset))
        end_offset = expr.source_range.end_pos.offset - 1
        parsed_value = [expr]
      end
      node = Tree::PropNode.new(parse_interp(name), parsed_value, prop)
      node.value_source_range = Sass::Source::Range.new(
        Sass::Source::Position.new(line.index, to_parser_offset(start_offset)),
        Sass::Source::Position.new(line.index, to_parser_offset(end_offset)),
        @options[:filename], @options[:importer])
      if !node.custom_property? && value.strip.empty? && line.children.empty?
        raise SyntaxError.new(
          "Invalid property: \"#{node.declaration}\" (no value)." +
          node.pseudo_class_selector_message)
      end

      node
    end

    def parse_variable(line)
      name, value, flags = line.text.scan(Script::MATCH)[0]
      raise SyntaxError.new("Illegal nesting: Nothing may be nested beneath variable declarations.",
        :line => @line + 1) unless line.children.empty?
      raise SyntaxError.new("Invalid variable: \"#{line.text}\".",
        :line => @line) unless name && value
      flags = flags ? flags.split(/\s+/) : []
      if (invalid_flag = flags.find {|f| f != '!default' && f != '!global'})
        raise SyntaxError.new("Invalid flag \"#{invalid_flag}\".", :line => @line)
      end

      # This workaround is needed for the case when the variable value is part of the identifier,
      # otherwise we end up with the offset equal to the value index inside the name:
      # $red_color: red;
      var_lhs_length = 1 + name.length # 1 stands for '$'
      index = line.text.index(value, line.offset + var_lhs_length) || 0
      expr = parse_script(value, :offset => to_parser_offset(line.offset + index))

      Tree::VariableNode.new(name, expr, flags.include?('!default'), flags.include?('!global'))
    end

    def parse_comment(line)
      if line.text[1] == CSS_COMMENT_CHAR || line.text[1] == SASS_COMMENT_CHAR
        silent = line.text[1] == SASS_COMMENT_CHAR
        loud = !silent && line.text[2] == SASS_LOUD_COMMENT_CHAR
        if silent
          value = [line.text]
        else
          value = self.class.parse_interp(
            line.text, line.index, to_parser_offset(line.offset), :filename => @filename)
        end
        value = Sass::Util.with_extracted_values(value) do |str|
          str = str.gsub(/^#{line.comment_tab_str}/m, '')[2..-1] # get rid of // or /*
          format_comment_text(str, silent)
        end
        type = if silent
                 :silent
               elsif loud
                 :loud
               else
                 :normal
               end
        comment = Tree::CommentNode.new(value, type)
        comment.line = line.index
        text = line.text.rstrip
        if text.include?("\n")
          end_offset = text.length - text.rindex("\n")
        else
          end_offset = to_parser_offset(line.offset + text.length)
        end
        comment.source_range = Sass::Source::Range.new(
          Sass::Source::Position.new(@line, to_parser_offset(line.offset)),
          Sass::Source::Position.new(@line + text.count("\n"), end_offset),
          @options[:filename])
        comment
      else
        Tree::RuleNode.new(parse_interp(line.text), full_line_range(line))
      end
    end

    DIRECTIVES = Set[:mixin, :include, :function, :return, :debug, :warn, :for,
      :each, :while, :if, :else, :extend, :import, :media, :charset, :content,
      :at_root, :error]

    def parse_directive(parent, line, root)
      directive, whitespace, value = line.text[1..-1].split(/(\s+)/, 2)
      raise SyntaxError.new("Invalid directive: '@'.") unless directive
      offset = directive.size + whitespace.size + 1 if whitespace

      directive_name = directive.tr('-', '_').to_sym
      if DIRECTIVES.include?(directive_name)
        return send("parse_#{directive_name}_directive", parent, line, root, value, offset)
      end

      unprefixed_directive = directive.gsub(/^-[a-z0-9]+-/i, '')
      if unprefixed_directive == 'supports'
        parser = Sass::SCSS::Parser.new(value, @options[:filename], @line)
        return Tree::SupportsNode.new(directive, parser.parse_supports_condition)
      end

      Tree::DirectiveNode.new(
        value.nil? ? ["@#{directive}"] : ["@#{directive} "] + parse_interp(value, offset))
    end

    def parse_while_directive(parent, line, root, value, offset)
      raise SyntaxError.new("Invalid while directive '@while': expected expression.") unless value
      Tree::WhileNode.new(parse_script(value, :offset => offset))
    end

    def parse_if_directive(parent, line, root, value, offset)
      raise SyntaxError.new("Invalid if directive '@if': expected expression.") unless value
      Tree::IfNode.new(parse_script(value, :offset => offset))
    end

    def parse_debug_directive(parent, line, root, value, offset)
      raise SyntaxError.new("Invalid debug directive '@debug': expected expression.") unless value
      raise SyntaxError.new("Illegal nesting: Nothing may be nested beneath debug directives.",
        :line => @line + 1) unless line.children.empty?
      offset = line.offset + line.text.index(value).to_i
      Tree::DebugNode.new(parse_script(value, :offset => offset))
    end

    def parse_error_directive(parent, line, root, value, offset)
      raise SyntaxError.new("Invalid error directive '@error': expected expression.") unless value
      raise SyntaxError.new("Illegal nesting: Nothing may be nested beneath error directives.",
        :line => @line + 1) unless line.children.empty?
      offset = line.offset + line.text.index(value).to_i
      Tree::ErrorNode.new(parse_script(value, :offset => offset))
    end

    def parse_extend_directive(parent, line, root, value, offset)
      raise SyntaxError.new("Invalid extend directive '@extend': expected expression.") unless value
      raise SyntaxError.new("Illegal nesting: Nothing may be nested beneath extend directives.",
        :line => @line + 1) unless line.children.empty?
      optional = !!value.gsub!(/\s+#{Sass::SCSS::RX::OPTIONAL}$/, '')
      offset = line.offset + line.text.index(value).to_i
      interp_parsed = parse_interp(value, offset)
      selector_range = Sass::Source::Range.new(
        Sass::Source::Position.new(@line, to_parser_offset(offset)),
        Sass::Source::Position.new(@line, to_parser_offset(line.offset) + line.text.length),
        @options[:filename], @options[:importer]
      )
      Tree::ExtendNode.new(interp_parsed, optional, selector_range)
    end

    def parse_warn_directive(parent, line, root, value, offset)
      raise SyntaxError.new("Invalid warn directive '@warn': expected expression.") unless value
      raise SyntaxError.new("Illegal nesting: Nothing may be nested beneath warn directives.",
        :line => @line + 1) unless line.children.empty?
      offset = line.offset + line.text.index(value).to_i
      Tree::WarnNode.new(parse_script(value, :offset => offset))
    end

    def parse_return_directive(parent, line, root, value, offset)
      raise SyntaxError.new("Invalid @return: expected expression.") unless value
      raise SyntaxError.new("Illegal nesting: Nothing may be nested beneath return directives.",
        :line => @line + 1) unless line.children.empty?
      offset = line.offset + line.text.index(value).to_i
      Tree::ReturnNode.new(parse_script(value, :offset => offset))
    end

    def parse_charset_directive(parent, line, root, value, offset)
      name = value && value[/\A(["'])(.*)\1\Z/, 2] # "
      raise SyntaxError.new("Invalid charset directive '@charset': expected string.") unless name
      raise SyntaxError.new("Illegal nesting: Nothing may be nested beneath charset directives.",
        :line => @line + 1) unless line.children.empty?
      Tree::CharsetNode.new(name)
    end

    def parse_media_directive(parent, line, root, value, offset)
      parser = Sass::SCSS::Parser.new(value,
        @options[:filename], @options[:importer],
        @line, to_parser_offset(@offset))
      offset = line.offset + line.text.index('media').to_i - 1
      parsed_media_query_list = parser.parse_media_query_list.to_a
      node = Tree::MediaNode.new(parsed_media_query_list)
      node.source_range = Sass::Source::Range.new(
        Sass::Source::Position.new(@line, to_parser_offset(offset)),
        Sass::Source::Position.new(@line, to_parser_offset(line.offset) + line.text.length),
        @options[:filename], @options[:importer])
      node
    end

    def parse_at_root_directive(parent, line, root, value, offset)
      return Sass::Tree::AtRootNode.new unless value

      if value.start_with?('(')
        parser = Sass::SCSS::Parser.new(value,
          @options[:filename], @options[:importer],
          @line, to_parser_offset(@offset))
        offset = line.offset + line.text.index('at-root').to_i - 1
        return Tree::AtRootNode.new(parser.parse_at_root_query)
      end

      at_root_node = Tree::AtRootNode.new
      parsed = parse_interp(value, offset)
      rule_node = Tree::RuleNode.new(parsed, full_line_range(line))

      # The caller expects to automatically add children to the returned node
      # and we want it to add children to the rule node instead, so we
      # manually handle the wiring here and return nil so the caller doesn't
      # duplicate our efforts.
      append_children(rule_node, line.children, false)
      at_root_node << rule_node
      parent << at_root_node
      nil
    end

    def parse_for_directive(parent, line, root, value, offset)
      var, from_expr, to_name, to_expr =
        value.scan(/^([^\s]+)\s+from\s+(.+)\s+(to|through)\s+(.+)$/).first

      if var.nil? # scan failed, try to figure out why for error message
        if value !~ /^[^\s]+/
          expected = "variable name"
        elsif value !~ /^[^\s]+\s+from\s+.+/
          expected = "'from <expr>'"
        else
          expected = "'to <expr>' or 'through <expr>'"
        end
        raise SyntaxError.new("Invalid for directive '@for #{value}': expected #{expected}.")
      end
      raise SyntaxError.new("Invalid variable \"#{var}\".") unless var =~ Script::VALIDATE

      var = var[1..-1]
      parsed_from = parse_script(from_expr, :offset => line.offset + line.text.index(from_expr))
      parsed_to = parse_script(to_expr, :offset => line.offset + line.text.index(to_expr))
      Tree::ForNode.new(var, parsed_from, parsed_to, to_name == 'to')
    end

    def parse_each_directive(parent, line, root, value, offset)
      vars, list_expr = value.scan(/^([^\s]+(?:\s*,\s*[^\s]+)*)\s+in\s+(.+)$/).first

      if vars.nil? # scan failed, try to figure out why for error message
        if value !~ /^[^\s]+/
          expected = "variable name"
        elsif value !~ /^[^\s]+(?:\s*,\s*[^\s]+)*[^\s]+\s+from\s+.+/
          expected = "'in <expr>'"
        end
        raise SyntaxError.new("Invalid each directive '@each #{value}': expected #{expected}.")
      end

      vars = vars.split(',').map do |var|
        var.strip!
        raise SyntaxError.new("Invalid variable \"#{var}\".") unless var =~ Script::VALIDATE
        var[1..-1]
      end

      parsed_list = parse_script(list_expr, :offset => line.offset + line.text.index(list_expr))
      Tree::EachNode.new(vars, parsed_list)
    end

    def parse_else_directive(parent, line, root, value, offset)
      previous = parent.children.last
      raise SyntaxError.new("@else must come after @if.") unless previous.is_a?(Tree::IfNode)

      if value
        if value !~ /^if\s+(.+)/
          raise SyntaxError.new("Invalid else directive '@else #{value}': expected 'if <expr>'.")
        end
        expr = parse_script($1, :offset => line.offset + line.text.index($1))
      end

      node = Tree::IfNode.new(expr)
      append_children(node, line.children, false)
      previous.add_else node
      nil
    end

    def parse_import_directive(parent, line, root, value, offset)
      raise SyntaxError.new("Illegal nesting: Nothing may be nested beneath import directives.",
        :line => @line + 1) unless line.children.empty?

      scanner = Sass::Util::MultibyteStringScanner.new(value)
      values = []

      loop do
        unless (node = parse_import_arg(scanner, offset + scanner.pos))
          raise SyntaxError.new(
            "Invalid @import: expected file to import, was #{scanner.rest.inspect}",
            :line => @line)
        end
        values << node
        break unless scanner.scan(/,\s*/)
      end

      if scanner.scan(/;/)
        raise SyntaxError.new("Invalid @import: expected end of line, was \";\".",
          :line => @line)
      end

      values
    end

    def parse_import_arg(scanner, offset)
      return if scanner.eos?

      if scanner.match?(/url\(/i)
        script_parser = Sass::Script::Parser.new(scanner, @line, to_parser_offset(offset), @options)
        str = script_parser.parse_string

        if scanner.eos?
          end_pos = str.source_range.end_pos
          node = Tree::CssImportNode.new(str)
        else
          supports_parser = Sass::SCSS::Parser.new(scanner,
            @options[:filename], @options[:importer],
            @line, str.source_range.end_pos.offset)
          supports_condition = supports_parser.parse_supports_clause

          if scanner.eos?
            node = Tree::CssImportNode.new(str, [], supports_condition)
          else
            media_parser = Sass::SCSS::Parser.new(scanner,
              @options[:filename], @options[:importer],
              @line, str.source_range.end_pos.offset)
            media = media_parser.parse_media_query_list
            end_pos = Sass::Source::Position.new(@line, media_parser.offset + 1)
            node = Tree::CssImportNode.new(str, media.to_a, supports_condition)
          end
        end

        node.source_range = Sass::Source::Range.new(
          str.source_range.start_pos, end_pos,
          @options[:filename], @options[:importer])
        return node
      end

      unless (quoted_val = scanner.scan(Sass::SCSS::RX::STRING))
        scanned = scanner.scan(/[^,;]+/)
        node = Tree::ImportNode.new(scanned)
        start_parser_offset = to_parser_offset(offset)
        node.source_range = Sass::Source::Range.new(
          Sass::Source::Position.new(@line, start_parser_offset),
          Sass::Source::Position.new(@line, start_parser_offset + scanned.length),
          @options[:filename], @options[:importer])
        return node
      end

      start_offset = offset
      offset += scanner.matched.length
      val = Sass::Script::Value::String.value(scanner[1] || scanner[2])
      scanned = scanner.scan(/\s*/)
      if !scanner.match?(/[,;]|$/)
        offset += scanned.length if scanned
        media_parser = Sass::SCSS::Parser.new(scanner,
          @options[:filename], @options[:importer], @line, offset)
        media = media_parser.parse_media_query_list
        node = Tree::CssImportNode.new(quoted_val, media.to_a)
        node.source_range = Sass::Source::Range.new(
          Sass::Source::Position.new(@line, to_parser_offset(start_offset)),
          Sass::Source::Position.new(@line, media_parser.offset),
          @options[:filename], @options[:importer])
      elsif val =~ %r{^(https?:)?//}
        node = Tree::CssImportNode.new(quoted_val)
        node.source_range = Sass::Source::Range.new(
          Sass::Source::Position.new(@line, to_parser_offset(start_offset)),
          Sass::Source::Position.new(@line, to_parser_offset(offset)),
          @options[:filename], @options[:importer])
      else
        node = Tree::ImportNode.new(val)
        node.source_range = Sass::Source::Range.new(
          Sass::Source::Position.new(@line, to_parser_offset(start_offset)),
          Sass::Source::Position.new(@line, to_parser_offset(offset)),
          @options[:filename], @options[:importer])
      end
      node
    end

    def parse_mixin_directive(parent, line, root, value, offset)
      parse_mixin_definition(line)
    end

    MIXIN_DEF_RE = /^(?:=|@mixin)\s*(#{Sass::SCSS::RX::IDENT})(.*)$/
    def parse_mixin_definition(line)
      name, arg_string = line.text.scan(MIXIN_DEF_RE).first
      raise SyntaxError.new("Invalid mixin \"#{line.text[1..-1]}\".") if name.nil?

      offset = line.offset + line.text.size - arg_string.size
      args, splat = Script::Parser.new(arg_string.strip, @line, to_parser_offset(offset), @options).
        parse_mixin_definition_arglist
      Tree::MixinDefNode.new(name, args, splat)
    end

    CONTENT_RE = /^@content\s*(.+)?$/
    def parse_content_directive(parent, line, root, value, offset)
      trailing = line.text.scan(CONTENT_RE).first.first
      unless trailing.nil?
        raise SyntaxError.new(
          "Invalid content directive. Trailing characters found: \"#{trailing}\".")
      end
      raise SyntaxError.new("Illegal nesting: Nothing may be nested beneath @content directives.",
        :line => line.index + 1) unless line.children.empty?
      Tree::ContentNode.new
    end

    def parse_include_directive(parent, line, root, value, offset)
      parse_mixin_include(line, root)
    end

    MIXIN_INCLUDE_RE = /^(?:\+|@include)\s*(#{Sass::SCSS::RX::IDENT})(.*)$/
    def parse_mixin_include(line, root)
      name, arg_string = line.text.scan(MIXIN_INCLUDE_RE).first
      raise SyntaxError.new("Invalid mixin include \"#{line.text}\".") if name.nil?

      offset = line.offset + line.text.size - arg_string.size
      args, keywords, splat, kwarg_splat =
        Script::Parser.new(arg_string.strip, @line, to_parser_offset(offset), @options).
          parse_mixin_include_arglist
      Tree::MixinNode.new(name, args, keywords, splat, kwarg_splat)
    end

    FUNCTION_RE = /^@function\s*(#{Sass::SCSS::RX::IDENT})(.*)$/
    def parse_function_directive(parent, line, root, value, offset)
      name, arg_string = line.text.scan(FUNCTION_RE).first
      raise SyntaxError.new("Invalid function definition \"#{line.text}\".") if name.nil?

      offset = line.offset + line.text.size - arg_string.size
      args, splat = Script::Parser.new(arg_string.strip, @line, to_parser_offset(offset), @options).
        parse_function_definition_arglist
      Tree::FunctionNode.new(name, args, splat)
    end

    def parse_script(script, options = {})
      line = options[:line] || @line
      offset = options[:offset] || @offset + 1
      Script.parse(script, line, offset, @options)
    end

    def format_comment_text(text, silent)
      content = text.split("\n")

      if content.first && content.first.strip.empty?
        removed_first = true
        content.shift
      end

      return "/* */" if content.empty?
      content.last.gsub!(%r{ ?\*/ *$}, '')
      first = content.shift unless removed_first
      content.map! {|l| l.gsub!(/^\*( ?)/, '\1') || (l.empty? ? "" : " ") + l}
      content.unshift first unless removed_first
      if silent
        "/*" + content.join("\n *") + " */"
      else
        # The #gsub fixes the case of a trailing */
        "/*" + content.join("\n *").gsub(/ \*\Z/, '') + " */"
      end
    end

    def parse_interp(text, offset = 0)
      self.class.parse_interp(text, @line, offset, :filename => @filename)
    end

    # Parser tracks 1-based line and offset, so our offset should be converted.
    def to_parser_offset(offset)
      offset + 1
    end

    def full_line_range(line)
      Sass::Source::Range.new(
        Sass::Source::Position.new(@line, to_parser_offset(line.offset)),
        Sass::Source::Position.new(@line, to_parser_offset(line.offset) + line.text.length),
        @options[:filename], @options[:importer])
    end

    # It's important that this have strings (at least)
    # at the beginning, the end, and between each Script::Tree::Node.
    #
    # @private
    def self.parse_interp(text, line, offset, options)
      res = []
      rest = Sass::Shared.handle_interpolation text do |scan|
        escapes = scan[2].size
        res << scan.matched[0...-2 - escapes]
        if escapes.odd?
          res << "\\" * (escapes - 1) << '#{'
        else
          res << "\\" * [0, escapes - 1].max
          if scan[1].include?("\n")
            line += scan[1].count("\n")
            offset = scan.matched_size - scan[1].rindex("\n")
          else
            offset += scan.matched_size
          end
          node = Script::Parser.new(scan, line, offset, options).parse_interpolated
          offset = node.source_range.end_pos.offset
          res << node
        end
      end
      res << rest
    end
  end
end
