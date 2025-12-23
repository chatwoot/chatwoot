# -*- coding: utf-8 -*-
require 'set'

module Sass
  module SCSS
    # The parser for SCSS.
    # It parses a string of code into a tree of {Sass::Tree::Node}s.
    class Parser
      # Expose for the SASS parser.
      attr_accessor :offset

      # @param str [String, StringScanner] The source document to parse.
      #   Note that `Parser` *won't* raise a nice error message if this isn't properly parsed;
      #   for that, you should use the higher-level {Sass::Engine} or {Sass::CSS}.
      # @param filename [String] The name of the file being parsed. Used for
      #   warnings and source maps.
      # @param importer [Sass::Importers::Base] The importer used to import the
      #   file being parsed. Used for source maps.
      # @param line [Integer] The 1-based line on which the source string appeared,
      #   if it's part of another document.
      # @param offset [Integer] The 1-based character (not byte) offset in the line on
      #   which the source string starts. Used for error reporting and sourcemap
      #   building.
      def initialize(str, filename, importer, line = 1, offset = 1)
        @template = str
        @filename = filename
        @importer = importer
        @line = line
        @offset = offset
        @strs = []
        @expected = nil
        @throw_error = false
      end

      # Parses an SCSS document.
      #
      # @return [Sass::Tree::RootNode] The root node of the document tree
      # @raise [Sass::SyntaxError] if there's a syntax error in the document
      def parse
        init_scanner!
        root = stylesheet
        expected("selector or at-rule") unless root && @scanner.eos?
        root
      end

      # Parses an identifier with interpolation.
      # Note that this won't assert that the identifier takes up the entire input string;
      # it's meant to be used with `StringScanner`s as part of other parsers.
      #
      # @return [Array<String, Sass::Script::Tree::Node>, nil]
      #   The interpolated identifier, or nil if none could be parsed
      def parse_interp_ident
        init_scanner!
        interp_ident
      end

      # Parses a supports clause for an @import directive
      def parse_supports_clause
        init_scanner!
        ss
        clause = supports_clause
        ss
        clause
      end

      # Parses a media query list.
      #
      # @return [Sass::Media::QueryList] The parsed query list
      # @raise [Sass::SyntaxError] if there's a syntax error in the query list,
      #   or if it doesn't take up the entire input string.
      def parse_media_query_list
        init_scanner!
        ql = media_query_list
        expected("media query list") unless ql && @scanner.eos?
        ql
      end

      # Parses an at-root query.
      #
      # @return [Array<String, Sass::Script;:Tree::Node>] The interpolated query.
      # @raise [Sass::SyntaxError] if there's a syntax error in the query,
      #   or if it doesn't take up the entire input string.
      def parse_at_root_query
        init_scanner!
        query = at_root_query
        expected("@at-root query list") unless query && @scanner.eos?
        query
      end

      # Parses a supports query condition.
      #
      # @return [Sass::Supports::Condition] The parsed condition
      # @raise [Sass::SyntaxError] if there's a syntax error in the condition,
      #   or if it doesn't take up the entire input string.
      def parse_supports_condition
        init_scanner!
        condition = supports_condition
        expected("supports condition") unless condition && @scanner.eos?
        condition
      end

      # Parses a custom property value.
      #
      # @return [Array<String, Sass::Script;:Tree::Node>] The interpolated value.
      # @raise [Sass::SyntaxError] if there's a syntax error in the value,
      #   or if it doesn't take up the entire input string.
      def parse_declaration_value
        init_scanner!
        value = declaration_value
        expected('"}"') unless value && @scanner.eos?
        value
      end

      private

      include Sass::SCSS::RX

      def source_position
        Sass::Source::Position.new(@line, @offset)
      end

      def range(start_pos, end_pos = source_position)
        Sass::Source::Range.new(start_pos, end_pos, @filename, @importer)
      end

      def init_scanner!
        @scanner =
          if @template.is_a?(StringScanner)
            @template
          else
            Sass::Util::MultibyteStringScanner.new(@template.tr("\r", ""))
          end
      end

      def stylesheet
        node = node(Sass::Tree::RootNode.new(@scanner.string), source_position)
        block_contents(node, :stylesheet) {s(node)}
      end

      def s(node)
        while tok(S) || tok(CDC) || tok(CDO) || (c = tok(SINGLE_LINE_COMMENT)) || (c = tok(COMMENT))
          next unless c
          process_comment c, node
          c = nil
        end
        true
      end

      def ss
        nil while tok(S) || tok(SINGLE_LINE_COMMENT) || tok(COMMENT)
        true
      end

      def ss_comments(node)
        while tok(S) || (c = tok(SINGLE_LINE_COMMENT)) || (c = tok(COMMENT))
          next unless c
          process_comment c, node
          c = nil
        end

        true
      end

      def whitespace
        return unless tok(S) || tok(SINGLE_LINE_COMMENT) || tok(COMMENT)
        ss
      end

      def process_comment(text, node)
        silent = text =~ %r{\A//}
        loud = !silent && text =~ %r{\A/[/*]!}
        line = @line - text.count("\n")
        comment_start = @scanner.pos - text.length
        index_before_line = @scanner.string.rindex("\n", comment_start) || -1
        offset = comment_start - index_before_line

        if silent
          value = [text.sub(%r{\A\s*//}, '/*').gsub(%r{^\s*//}, ' *') + ' */']
        else
          value = Sass::Engine.parse_interp(text, line, offset, :filename => @filename)
          line_before_comment = @scanner.string[index_before_line + 1...comment_start]
          value.unshift(line_before_comment.gsub(/[^\s]/, ' '))
        end

        type = if silent
                 :silent
               elsif loud
                 :loud
               else
                 :normal
               end
        start_pos = Sass::Source::Position.new(line, offset)
        comment = node(Sass::Tree::CommentNode.new(value, type), start_pos)
        node << comment
      end

      DIRECTIVES = Set[:mixin, :include, :function, :return, :debug, :warn, :for,
        :each, :while, :if, :else, :extend, :import, :media, :charset, :content,
        :_moz_document, :at_root, :error]

      PREFIXED_DIRECTIVES = Set[:supports]

      def directive
        start_pos = source_position
        return unless tok(/@/)
        name = ident!
        ss

        if (dir = special_directive(name, start_pos))
          return dir
        elsif (dir = prefixed_directive(name, start_pos))
          return dir
        end

        val = almost_any_value
        val = val ? ["@#{name} "] + Sass::Util.strip_string_array(val) : ["@#{name}"]
        directive_body(val, start_pos)
      end

      def directive_body(value, start_pos)
        node = Sass::Tree::DirectiveNode.new(value)

        if tok(/\{/)
          node.has_children = true
          block_contents(node, :directive)
          tok!(/\}/)
        end

        node(node, start_pos)
      end

      def special_directive(name, start_pos)
        sym = name.tr('-', '_').to_sym
        DIRECTIVES.include?(sym) && send("#{sym}_directive", start_pos)
      end

      def prefixed_directive(name, start_pos)
        sym = deprefix(name).tr('-', '_').to_sym
        PREFIXED_DIRECTIVES.include?(sym) && send("#{sym}_directive", name, start_pos)
      end

      def mixin_directive(start_pos)
        name = ident!
        args, splat = sass_script(:parse_mixin_definition_arglist)
        ss
        block(node(Sass::Tree::MixinDefNode.new(name, args, splat), start_pos), :directive)
      end

      def include_directive(start_pos)
        name = ident!
        args, keywords, splat, kwarg_splat = sass_script(:parse_mixin_include_arglist)
        ss
        include_node = node(
          Sass::Tree::MixinNode.new(name, args, keywords, splat, kwarg_splat), start_pos)
        if tok?(/\{/)
          include_node.has_children = true
          block(include_node, :directive)
        else
          include_node
        end
      end

      def content_directive(start_pos)
        ss
        node(Sass::Tree::ContentNode.new, start_pos)
      end

      def function_directive(start_pos)
        name = ident!
        args, splat = sass_script(:parse_function_definition_arglist)
        ss
        block(node(Sass::Tree::FunctionNode.new(name, args, splat), start_pos), :function)
      end

      def return_directive(start_pos)
        node(Sass::Tree::ReturnNode.new(sass_script(:parse)), start_pos)
      end

      def debug_directive(start_pos)
        node(Sass::Tree::DebugNode.new(sass_script(:parse)), start_pos)
      end

      def warn_directive(start_pos)
        node(Sass::Tree::WarnNode.new(sass_script(:parse)), start_pos)
      end

      def for_directive(start_pos)
        tok!(/\$/)
        var = ident!
        ss

        tok!(/from/)
        from = sass_script(:parse_until, Set["to", "through"])
        ss

        @expected = '"to" or "through"'
        exclusive = (tok(/to/) || tok!(/through/)) == 'to'
        to = sass_script(:parse)
        ss

        block(node(Sass::Tree::ForNode.new(var, from, to, exclusive), start_pos), :directive)
      end

      def each_directive(start_pos)
        tok!(/\$/)
        vars = [ident!]
        ss
        while tok(/,/)
          ss
          tok!(/\$/)
          vars << ident!
          ss
        end

        tok!(/in/)
        list = sass_script(:parse)
        ss

        block(node(Sass::Tree::EachNode.new(vars, list), start_pos), :directive)
      end

      def while_directive(start_pos)
        expr = sass_script(:parse)
        ss
        block(node(Sass::Tree::WhileNode.new(expr), start_pos), :directive)
      end

      def if_directive(start_pos)
        expr = sass_script(:parse)
        ss
        node = block(node(Sass::Tree::IfNode.new(expr), start_pos), :directive)
        pos = @scanner.pos
        line = @line
        ss

        else_block(node) ||
          begin
            # Backtrack in case there are any comments we want to parse
            @scanner.pos = pos
            @line = line
            node
          end
      end

      def else_block(node)
        start_pos = source_position
        return unless tok(/@else/)
        ss
        else_node = block(
          node(Sass::Tree::IfNode.new((sass_script(:parse) if tok(/if/))), start_pos),
          :directive)
        node.add_else(else_node)
        pos = @scanner.pos
        line = @line
        ss

        else_block(node) ||
          begin
            # Backtrack in case there are any comments we want to parse
            @scanner.pos = pos
            @line = line
            node
          end
      end

      def else_directive(start_pos)
        err("Invalid CSS: @else must come after @if")
      end

      def extend_directive(start_pos)
        selector_start_pos = source_position
        @expected = "selector"
        selector = Sass::Util.strip_string_array(expr!(:almost_any_value))
        optional = tok(OPTIONAL)
        ss
        node(Sass::Tree::ExtendNode.new(selector, !!optional, range(selector_start_pos)), start_pos)
      end

      def import_directive(start_pos)
        values = []

        loop do
          values << expr!(:import_arg)
          break if use_css_import?
          break unless tok(/,/)
          ss
        end

        values
      end

      def import_arg
        start_pos = source_position
        return unless (str = string) || (uri = tok?(/url\(/i))
        if uri
          str = sass_script(:parse_string)
          ss
          supports = supports_clause
          ss
          media = media_query_list
          ss
          return node(Tree::CssImportNode.new(str, media.to_a, supports), start_pos)
        end
        ss

        supports = supports_clause
        ss
        media = media_query_list
        if str =~ %r{^(https?:)?//} || media || supports || use_css_import?
          return node(
            Sass::Tree::CssImportNode.new(
              Sass::Script::Value::String.quote(str), media.to_a, supports), start_pos)
        end

        node(Sass::Tree::ImportNode.new(str.strip), start_pos)
      end

      def use_css_import?; false; end

      def media_directive(start_pos)
        block(node(Sass::Tree::MediaNode.new(expr!(:media_query_list).to_a), start_pos), :directive)
      end

      # http://www.w3.org/TR/css3-mediaqueries/#syntax
      def media_query_list
        query = media_query
        return unless query
        queries = [query]

        ss
        while tok(/,/)
          ss; queries << expr!(:media_query)
        end
        ss

        Sass::Media::QueryList.new(queries)
      end

      def media_query
        if (ident1 = interp_ident)
          ss
          ident2 = interp_ident
          ss
          if ident2 && ident2.length == 1 && ident2[0].is_a?(String) && ident2[0].downcase == 'and'
            query = Sass::Media::Query.new([], ident1, [])
          else
            if ident2
              query = Sass::Media::Query.new(ident1, ident2, [])
            else
              query = Sass::Media::Query.new([], ident1, [])
            end
            return query unless tok(/and/i)
            ss
          end
        end

        if query
          expr = expr!(:media_expr)
        else
          expr = media_expr
          return unless expr
        end
        query ||= Sass::Media::Query.new([], [], [])
        query.expressions << expr

        ss
        while tok(/and/i)
          ss; query.expressions << expr!(:media_expr)
        end

        query
      end

      def query_expr
        interp = interpolation
        return interp if interp
        return unless tok(/\(/)
        res = ['(']
        ss
        stop_at = Set[:single_eq, :lt, :lte, :gt, :gte]
        res << sass_script(:parse_until, stop_at)

        if tok(/:/)
          res << ': '
          ss
          res << sass_script(:parse)
        elsif comparison1 = tok(/=|[<>]=?/)
          res << ' ' << comparison1 << ' '
          ss
          res << sass_script(:parse_until, stop_at)
          if ((comparison1 == ">" || comparison1 == ">=") && comparison2 = tok(/>=?/)) ||
             ((comparison1 == "<" || comparison1 == "<=") && comparison2 = tok(/<=?/))
            res << ' ' << comparison2 << ' '
            ss
            res << sass_script(:parse_until, stop_at)
          end
        end
        res << tok!(/\)/)
        ss
        res
      end

      # Aliases allow us to use different descriptions if the same
      # expression fails in different contexts.
      alias_method :media_expr, :query_expr
      alias_method :at_root_query, :query_expr

      def charset_directive(start_pos)
        name = expr!(:string)
        ss
        node(Sass::Tree::CharsetNode.new(name), start_pos)
      end

      # The document directive is specified in
      # http://www.w3.org/TR/css3-conditional/, but Gecko allows the
      # `url-prefix` and `domain` functions to omit quotation marks, contrary to
      # the standard.
      #
      # We could parse all document directives according to Mozilla's syntax,
      # but if someone's using e.g. @-webkit-document we don't want them to
      # think WebKit works sans quotes.
      def _moz_document_directive(start_pos)
        res = ["@-moz-document "]
        loop do
          res << str {ss} << expr!(:moz_document_function)
          if (c = tok(/,/))
            res << c
          else
            break
          end
        end
        directive_body(res.flatten, start_pos)
      end

      def moz_document_function
        val = interp_uri || _interp_string(:url_prefix) ||
          _interp_string(:domain) || function(false) || interpolation
        return unless val
        ss
        val
      end

      def at_root_directive(start_pos)
        if tok?(/\(/) && (expr = at_root_query)
          return block(node(Sass::Tree::AtRootNode.new(expr), start_pos), :directive)
        end

        at_root_node = node(Sass::Tree::AtRootNode.new, start_pos)
        rule_node = ruleset
        return block(at_root_node, :stylesheet) unless rule_node
        at_root_node << rule_node
        at_root_node
      end

      def at_root_directive_list
        return unless (first = ident)
        arr = [first]
        ss
        while (e = ident)
          arr << e
          ss
        end
        arr
      end

      def error_directive(start_pos)
        node(Sass::Tree::ErrorNode.new(sass_script(:parse)), start_pos)
      end

      # http://www.w3.org/TR/css3-conditional/
      def supports_directive(name, start_pos)
        condition = expr!(:supports_condition)
        node = Sass::Tree::SupportsNode.new(name, condition)

        tok!(/\{/)
        node.has_children = true
        block_contents(node, :directive)
        tok!(/\}/)

        node(node, start_pos)
      end

      def supports_clause
        return unless tok(/supports\(/i)
        ss
        supports = import_supports_condition
        ss
        tok!(/\)/)
        supports
      end

      def supports_condition
        supports_negation || supports_operator || supports_interpolation
      end

      def import_supports_condition
        supports_condition || supports_declaration
      end

      def supports_negation
        return unless tok(/not/i)
        ss
        Sass::Supports::Negation.new(expr!(:supports_condition_in_parens))
      end

      def supports_operator
        cond = supports_condition_in_parens
        return unless cond
        re = /and|or/i
        while (op = tok(re))
          re = /#{op}/i
          ss
          cond = Sass::Supports::Operator.new(
            cond, expr!(:supports_condition_in_parens), op)
        end
        cond
      end

      def supports_declaration
          name = sass_script(:parse)
          tok!(/:/); ss
          value = sass_script(:parse)
          Sass::Supports::Declaration.new(name, value)
      end

      def supports_condition_in_parens
        interp = supports_interpolation
        return interp if interp
        return unless tok(/\(/); ss
        if (cond = supports_condition)
          tok!(/\)/); ss
          cond
        else
          decl = supports_declaration
          tok!(/\)/); ss
          decl
        end
      end

      def supports_interpolation
        interp = interpolation
        return unless interp
        ss
        Sass::Supports::Interpolation.new(interp)
      end

      def variable
        return unless tok(/\$/)
        start_pos = source_position
        name = ident!
        ss; tok!(/:/); ss

        expr = sass_script(:parse)
        while tok(/!/)
          flag_name = ident!
          if flag_name == 'default'
            guarded ||= true
          elsif flag_name == 'global'
            global ||= true
          else
            raise Sass::SyntaxError.new("Invalid flag \"!#{flag_name}\".", :line => @line)
          end
          ss
        end

        result = Sass::Tree::VariableNode.new(name, expr, guarded, global)
        node(result, start_pos)
      end

      def operator
        # Many of these operators (all except / and ,)
        # are disallowed by the CSS spec,
        # but they're included here for compatibility
        # with some proprietary MS properties
        str {ss if tok(%r{[/,:.=]})}
      end

      def ruleset
        start_pos = source_position
        return unless (rules = almost_any_value)
        block(
          node(
            Sass::Tree::RuleNode.new(rules, range(start_pos)), start_pos), :ruleset)
      end

      def block(node, context)
        node.has_children = true
        tok!(/\{/)
        block_contents(node, context)
        tok!(/\}/)
        node
      end

      # A block may contain declarations and/or rulesets
      def block_contents(node, context)
        block_given? ? yield : ss_comments(node)
        node << (child = block_child(context))
        while tok(/;/) || has_children?(child)
          block_given? ? yield : ss_comments(node)
          node << (child = block_child(context))
        end
        node
      end

      def block_child(context)
        return variable || directive if context == :function
        return variable || directive || ruleset if context == :stylesheet
        variable || directive || declaration_or_ruleset
      end

      def has_children?(child_or_array)
        return false unless child_or_array
        return child_or_array.last.has_children if child_or_array.is_a?(Array)
        child_or_array.has_children
      end

      # When parsing the contents of a ruleset, it can be difficult to tell
      # declarations apart from nested rulesets. Since we don't thoroughly parse
      # selectors until after resolving interpolation, we can share a bunch of
      # the parsing of the two, but we need to disambiguate them first. We use
      # the following criteria:
      #
      # * If the entity doesn't start with an identifier followed by a colon,
      #   it's a selector. There are some additional mostly-unimportant cases
      #   here to support various declaration hacks.
      #
      # * If the colon is followed by another colon, it's a selector.
      #
      # * Otherwise, if the colon is followed by anything other than
      #   interpolation or a character that's valid as the beginning of an
      #   identifier, it's a declaration.
      #
      # * If the colon is followed by interpolation or a valid identifier, try
      #   parsing it as a declaration value. If this fails, backtrack and parse
      #   it as a selector.
      #
      # * If the declaration value value valid but is followed by "{", backtrack
      #   and parse it as a selector anyway. This ensures that ".foo:bar {" is
      #   always parsed as a selector and never as a property with nested
      #   properties beneath it.
      def declaration_or_ruleset
        start_pos = source_position
        declaration = try_declaration

        if declaration.nil?
          return unless (selector = almost_any_value)
        elsif declaration.is_a?(Array)
          selector = declaration
        else
          # Declaration should be a PropNode.
          return declaration
        end

        if (additional_selector = almost_any_value)
          selector << additional_selector
        end

        block(
          node(
            Sass::Tree::RuleNode.new(merge(selector), range(start_pos)), start_pos), :ruleset)
      end

      # Tries to parse a declaration, and returns the value parsed so far if it
      # fails.
      #
      # This has three possible return types. It can return `nil`, indicating
      # that parsing failed completely and the scanner hasn't moved forward at
      # all. It can return an Array, indicating that parsing failed after
      # consuming some text (possibly containing interpolation), which is
      # returned. Or it can return a PropNode, indicating that parsing
      # succeeded.
      def try_declaration
        # This allows the "*prop: val", ":prop: val", "#prop: val", and ".prop:
        # val" hacks.
        name_start_pos = source_position
        if (s = tok(/[:\*\.]|\#(?!\{)/))
          name = [s, str {ss}]
          return name unless (ident = interp_ident)
          name << ident
        else
          return unless (name = interp_ident)
          name = Array(name)
        end

        if (comment = tok(COMMENT))
          name << comment
        end
        name_end_pos = source_position

        mid = [str {ss}]
        return name + mid unless tok(/:/)
        mid << ':'

        # If this is a CSS variable, parse it as a property no matter what.
        if name.first.is_a?(String) && name.first.start_with?("--")
          return css_variable_declaration(name, name_start_pos, name_end_pos)
        end

        return name + mid + [':'] if tok(/:/)
        mid << str {ss}
        post_colon_whitespace = !mid.last.empty?
        could_be_selector = !post_colon_whitespace && (tok?(IDENT_START) || tok?(INTERP_START))

        value_start_pos = source_position
        value = nil
        error = catch_error do
          value = value!
          if tok?(/\{/)
            # Properties that are ambiguous with selectors can't have additional
            # properties nested beneath them.
            tok!(/;/) if could_be_selector
          elsif !tok?(/[;{}]/)
            # We want an exception if there's no valid end-of-property character
            # exists, but we don't want to consume it if it does.
            tok!(/[;{}]/)
          end
        end

        if error
          rethrow error unless could_be_selector

          # If the value would be followed by a semicolon, it's definitely
          # supposed to be a property, not a selector.
          additional_selector = almost_any_value
          rethrow error if tok?(/;/)

          return name + mid + (additional_selector || [])
        end

        value_end_pos = source_position
        ss
        require_block = tok?(/\{/)

        node = node(Sass::Tree::PropNode.new(name.flatten.compact, [value], :new),
                    name_start_pos, value_end_pos)
        node.name_source_range = range(name_start_pos, name_end_pos)
        node.value_source_range = range(value_start_pos, value_end_pos)

        return node unless require_block
        nested_properties! node
      end

      def css_variable_declaration(name, name_start_pos, name_end_pos)
        value_start_pos = source_position
        value = declaration_value
        value_end_pos = source_position

        node = node(Sass::Tree::PropNode.new(name.flatten.compact, value, :new),
                    name_start_pos, value_end_pos)
        node.name_source_range = range(name_start_pos, name_end_pos)
        node.value_source_range = range(value_start_pos, value_end_pos)
        node
      end

      # This production consumes values that could be a selector, an expression,
      # or a combination of both. It respects strings and comments and supports
      # interpolation. It will consume up to "{", "}", ";", or "!".
      #
      # Values consumed by this production will usually be parsed more
      # thoroughly once interpolation has been resolved.
      def almost_any_value
        return unless (tok = almost_any_value_token)
        sel = [tok]
        while (tok = almost_any_value_token)
          sel << tok
        end
        merge(sel)
      end

      def almost_any_value_token
        tok(%r{
          (
            \\.
          |
            (?!url\()
            [^"'/\#!;\{\}] # "
          |
            # interp_uri will handle most url() calls, but not ones that take strings
            url\(#{W}(?=")
          |
            /(?![/*])
          |
            \#(?!\{)
          |
            !(?![a-z]) # TODO: never consume "!" when issue 1126 is fixed.
          )+
        }xi) || tok(COMMENT) || tok(SINGLE_LINE_COMMENT) || interp_string || interp_uri ||
                interpolation(:warn_for_color)
      end

      def declaration_value(top_level: true)
        return unless (tok = declaration_value_token(top_level))
        value = [tok]
        while (tok = declaration_value_token(top_level))
          value << tok
        end
        merge(value)
      end

      def declaration_value_token(top_level)
        # This comes, more or less, from the [token consumption algorithm][].
        # However, since we don't have to worry about the token semantics, we
        # just consume everything until we come across a token with special
        # semantics.
        #
        # [token consumption algorithm]: https://drafts.csswg.org/css-syntax-3/#consume-token.
        result = tok(%r{
          (
            (?!
              url\(
            )
            [^()\[\]{}"'#/ \t\r\n\f#{top_level ? ";" : ""}]
          |
            \#(?!\{)
          |
            /(?!\*)
          )+
        }xi) || interp_string || interp_uri || interpolation || tok(COMMENT)
        return result if result

        # Fold together multiple characters of whitespace that don't include
        # newlines. The value only cares about the tokenization, so this is safe
        # as long as we don't delete whitespace entirely. It's important that we
        # fold here rather than post-processing, since we aren't allowed to fold
        # whitespace within strings and we lose that context later on.
        if (ws = tok(S))
          return ws.include?("\n") ? ws.gsub(/\A[^\n]*/, '') : ' '
        end

        if tok(/\(/)
          value = declaration_value(top_level: false)
          tok!(/\)/)
          ['(', *value, ')']
        elsif tok(/\[/)
          value = declaration_value(top_level: false)
          tok!(/\]/)
          ['[', *value, ']']
        elsif tok(/\{/)
          value = declaration_value(top_level: false)
          tok!(/\}/)
          ['{', *value, '}']
        end
      end

      def declaration
        # This allows the "*prop: val", ":prop: val", "#prop: val", and ".prop:
        # val" hacks.
        name_start_pos = source_position
        if (s = tok(/[:\*\.]|\#(?!\{)/))
          name = [s, str {ss}, *expr!(:interp_ident)]
        else
          return unless (name = interp_ident)
          name = Array(name)
        end

        if (comment = tok(COMMENT))
          name << comment
        end
        name_end_pos = source_position
        ss

        tok!(/:/)
        ss
        value_start_pos = source_position
        value = value!
        value_end_pos = source_position
        ss
        require_block = tok?(/\{/)

        node = node(Sass::Tree::PropNode.new(name.flatten.compact, [value], :new),
                    name_start_pos, value_end_pos)
        node.name_source_range = range(name_start_pos, name_end_pos)
        node.value_source_range = range(value_start_pos, value_end_pos)

        return node unless require_block
        nested_properties! node
      end

      def value!
        if tok?(/\{/)
          str = Sass::Script::Tree::Literal.new(Sass::Script::Value::String.new(""))
          str.line = source_position.line
          str.source_range = range(source_position)
          return str
        end

        start_pos = source_position
        # This is a bit of a dirty trick:
        # if the value is completely static,
        # we don't parse it at all, and instead return a plain old string
        # containing the value.
        # This results in a dramatic speed increase.
        if (val = tok(STATIC_VALUE))
          # If val ends with escaped whitespace, leave it be.
          str = Sass::Script::Tree::Literal.new(
            Sass::Script::Value::String.new(
              Sass::Util.strip_except_escapes(val)))
          str.line = start_pos.line
          str.source_range = range(start_pos)
          return str
        end
        sass_script(:parse)
      end

      def nested_properties!(node)
        @expected = 'expression (e.g. 1px, bold) or "{"'
        block(node, :property)
      end

      def expr(allow_var = true)
        t = term(allow_var)
        return unless t
        res = [t, str {ss}]

        while (o = operator) && (t = term(allow_var))
          res << o << t << str {ss}
        end

        res.flatten
      end

      def term(allow_var)
        e = tok(NUMBER) ||
            interp_uri ||
            function(allow_var) ||
            interp_string ||
            tok(UNICODERANGE) ||
            interp_ident ||
            tok(HEXCOLOR) ||
            (allow_var && var_expr)
        return e if e

        op = tok(/[+-]/)
        return unless op
        @expected = "number or function"
        [op,
         tok(NUMBER) || function(allow_var) || (allow_var && var_expr) || expr!(:interpolation)]
      end

      def function(allow_var)
        name = tok(FUNCTION)
        return unless name
        if name == "expression(" || name == "calc("
          str, _ = Sass::Shared.balance(@scanner, ?(, ?), 1)
          [name, str]
        else
          [name, str {ss}, expr(allow_var), tok!(/\)/)]
        end
      end

      def var_expr
        return unless tok(/\$/)
        line = @line
        var = Sass::Script::Tree::Variable.new(ident!)
        var.line = line
        var
      end

      def interpolation(warn_for_color = false)
        return unless tok(INTERP_START)
        sass_script(:parse_interpolated, warn_for_color)
      end

      def string
        return unless tok(STRING)
        Sass::Script::Value::String.value(@scanner[1] || @scanner[2])
      end

      def interp_string
        _interp_string(:double) || _interp_string(:single)
      end

      def interp_uri
        _interp_string(:uri)
      end

      def _interp_string(type)
        start = tok(Sass::Script::Lexer::STRING_REGULAR_EXPRESSIONS[type][false])
        return unless start
        res = [start]

        mid_re = Sass::Script::Lexer::STRING_REGULAR_EXPRESSIONS[type][true]
        # @scanner[2].empty? means we've started an interpolated section
        while @scanner[2] == '#{'
          @scanner.pos -= 2 # Don't consume the #{
          res.last.slice!(-2..-1)
          res << expr!(:interpolation) << tok(mid_re)
        end
        res
      end

      def ident
        (ident = tok(IDENT)) && Sass::Util.normalize_ident_escapes(ident)
      end

      def ident!
        Sass::Util.normalize_ident_escapes(tok!(IDENT))
      end

      def name
        (name = tok(NAME)) && Sass::Util.normalize_ident_escapes(name)
      end

      def name!
        Sass::Util.normalize_ident_escapes(tok!(NAME))
      end

      def interp_ident
        val = ident || interpolation(:warn_for_color) || tok(IDENT_HYPHEN_INTERP)
        return unless val
        res = [val]
        while (val = name || interpolation(:warn_for_color))
          res << val
        end
        res
      end

      def interp_ident_or_var
        id = interp_ident
        return id if id
        var = var_expr
        return [var] if var
      end

      def str
        @strs.push String.new("")
        yield
        @strs.last
      ensure
        @strs.pop
      end

      def str?
        pos = @scanner.pos
        line = @line
        offset = @offset
        @strs.push ""
        throw_error {yield} && @strs.last
      rescue Sass::SyntaxError
        @scanner.pos = pos
        @line = line
        @offset = offset
        nil
      ensure
        @strs.pop
      end

      def node(node, start_pos, end_pos = source_position)
        node.line = start_pos.line
        node.source_range = range(start_pos, end_pos)
        node
      end

      @sass_script_parser = Sass::Script::Parser

      class << self
        # @private
        attr_accessor :sass_script_parser
      end

      def sass_script(*args)
        parser = self.class.sass_script_parser.new(@scanner, @line, @offset,
          :filename => @filename, :importer => @importer, :allow_extra_text => true)
        result = parser.send(*args)
        unless @strs.empty?
          # Convert to CSS manually so that comments are ignored.
          src = result.to_sass
          @strs.each {|s| s << src}
        end
        @line = parser.line
        @offset = parser.offset
        result
      rescue Sass::SyntaxError => e
        throw(:_sass_parser_error, true) if @throw_error
        raise e
      end

      def merge(arr)
        arr && Sass::Util.merge_adjacent_strings([arr].flatten)
      end

      EXPR_NAMES = {
        :media_query => "media query (e.g. print, screen, print and screen)",
        :media_query_list => "media query (e.g. print, screen, print and screen)",
        :media_expr => "media expression (e.g. (min-device-width: 800px))",
        :at_root_query => "@at-root query (e.g. (without: media))",
        :at_root_directive_list => '* or identifier',
        :declaration_value => "expression (e.g. fr, 2n+1)",
        :interp_ident => "identifier",
        :qualified_name => "identifier",
        :expr => "expression (e.g. 1px, bold)",
        :selector_comma_sequence => "selector",
        :string => "string",
        :import_arg => "file to import (string or url())",
        :moz_document_function => "matching function (e.g. url-prefix(), domain())",
        :supports_condition => "@supports condition (e.g. (display: flexbox))",
        :supports_condition_in_parens => "@supports condition (e.g. (display: flexbox))",
        :a_n_plus_b => "An+B expression",
        :keyframes_selector_component => "from, to, or a percentage",
        :keyframes_selector => "keyframes selector (e.g. 10%)"
      }

      TOK_NAMES = Hash[Sass::SCSS::RX.constants.map do |c|
        [Sass::SCSS::RX.const_get(c), c.downcase]
      end].merge(
        IDENT => "identifier",
        /[;{}]/ => '";"',
        /\b(without|with)\b/ => '"with" or "without"'
      )

      def tok?(rx)
        @scanner.match?(rx)
      end

      def expr!(name)
        e = send(name)
        return e if e
        expected(EXPR_NAMES[name] || name.to_s)
      end

      def tok!(rx)
        t = tok(rx)
        return t if t
        name = TOK_NAMES[rx]

        unless name
          # Display basic regexps as plain old strings
          source = rx.source.gsub(%r{\\/}, '/')
          string = rx.source.gsub(/\\(.)/, '\1')
          name = source == Regexp.escape(string) ? string.inspect : rx.inspect
        end

        expected(name)
      end

      def expected(name)
        throw(:_sass_parser_error, true) if @throw_error
        self.class.expected(@scanner, @expected || name, @line)
      end

      def err(msg)
        throw(:_sass_parser_error, true) if @throw_error
        raise Sass::SyntaxError.new(msg, :line => @line)
      end

      def throw_error
        old_throw_error, @throw_error = @throw_error, false
        yield
      ensure
        @throw_error = old_throw_error
      end

      def catch_error(&block)
        old_throw_error, @throw_error = @throw_error, true
        pos = @scanner.pos
        line = @line
        offset = @offset
        expected = @expected

        logger = Sass::Logger::Delayed.install!
        if catch(:_sass_parser_error) {yield; false}
          @scanner.pos = pos
          @line = line
          @offset = offset
          @expected = expected
          {:pos => pos, :line => line, :expected => @expected, :block => block}
        else
          logger.flush
          nil
        end
      ensure
        logger.uninstall! if logger
        @throw_error = old_throw_error
      end

      def rethrow(err)
        if @throw_error
          throw :_sass_parser_error, err
        else
          @scanner = Sass::Util::MultibyteStringScanner.new(@scanner.string)
          @scanner.pos = err[:pos]
          @line = err[:line]
          @expected = err[:expected]
          err[:block].call
        end
      end

      # @private
      def self.expected(scanner, expected, line)
        pos = scanner.pos

        after = scanner.string[0...pos]
        # Get rid of whitespace between pos and the last token,
        # but only if there's a newline in there
        after.gsub!(/\s*\n\s*$/, '')
        # Also get rid of stuff before the last newline
        after.gsub!(/.*\n/, '')
        after = "..." + after[-15..-1] if after.size > 18

        was = scanner.rest.dup
        # Get rid of whitespace between pos and the next token,
        # but only if there's a newline in there
        was.gsub!(/^\s*\n\s*/, '')
        # Also get rid of stuff after the next newline
        was.gsub!(/\n.*/, '')
        was = was[0...15] + "..." if was.size > 18

        raise Sass::SyntaxError.new(
          "Invalid CSS after \"#{after}\": expected #{expected}, was \"#{was}\"",
          :line => line)
      end

      # Avoid allocating lots of new strings for `#tok`.
      # This is important because `#tok` is called all the time.
      NEWLINE = "\n"

      def tok(rx)
        res = @scanner.scan(rx)

        return unless res

        newline_count = res.count(NEWLINE)
        if newline_count > 0
          @line += newline_count
          @offset = res[res.rindex(NEWLINE)..-1].size
        else
          @offset += res.size
        end

        @expected = nil
        if !@strs.empty? && rx != COMMENT && rx != SINGLE_LINE_COMMENT
          @strs.each {|s| s << res}
        end
        res
      end

      # Remove a vendor prefix from `str`.
      def deprefix(str)
        str.gsub(/^-[a-zA-Z0-9]+-/, '')
      end
    end
  end
end
