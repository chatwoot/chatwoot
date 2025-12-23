require 'sass/script/css_parser'

module Sass
  module SCSS
    # A parser for a static SCSS tree.
    # Parses with SCSS extensions, like nested rules and parent selectors,
    # but without dynamic SassScript.
    # This is useful for e.g. \{#parse\_selector parsing selectors}
    # after resolving the interpolation.
    class StaticParser < Parser
      # Parses the text as a selector.
      #
      # @param filename [String, nil] The file in which the selector appears,
      #   or nil if there is no such file.
      #   Used for error reporting.
      # @return [Selector::CommaSequence] The parsed selector
      # @raise [Sass::SyntaxError] if there's a syntax error in the selector
      def parse_selector
        init_scanner!
        seq = expr!(:selector_comma_sequence)
        expected("selector") unless @scanner.eos?
        seq.line = @line
        seq.filename = @filename
        seq
      end

      # Parses a static at-root query.
      #
      # @return [(Symbol, Array<String>)] The type of the query
      #   (`:with` or `:without`) and the values that are being filtered.
      # @raise [Sass::SyntaxError] if there's a syntax error in the query,
      #   or if it doesn't take up the entire input string.
      def parse_static_at_root_query
        init_scanner!
        tok!(/\(/); ss
        type = tok!(/\b(without|with)\b/).to_sym; ss
        tok!(/:/); ss
        directives = expr!(:at_root_directive_list); ss
        tok!(/\)/)
        expected("@at-root query list") unless @scanner.eos?
        return type, directives
      end

      def parse_keyframes_selector
        init_scanner!
        sel = expr!(:keyframes_selector)
        expected("keyframes selector") unless @scanner.eos?
        sel
      end

      # @see Parser#initialize
      # @param allow_parent_ref [Boolean] Whether to allow the
      #   parent-reference selector, `&`, when parsing the document.
      def initialize(str, filename, importer, line = 1, offset = 1, allow_parent_ref = true)
        super(str, filename, importer, line, offset)
        @allow_parent_ref = allow_parent_ref
      end

      private

      def moz_document_function
        val = tok(URI) || tok(URL_PREFIX) || tok(DOMAIN) || function(false)
        return unless val
        ss
        [val]
      end

      def variable; nil; end
      def script_value; nil; end
      def interpolation(warn_for_color = false); nil; end
      def var_expr; nil; end
      def interp_string; (s = tok(STRING)) && [s]; end
      def interp_uri; (s = tok(URI)) && [s]; end
      def interp_ident; (s = ident) && [s]; end
      def use_css_import?; true; end

      def special_directive(name, start_pos)
        return unless %w(media import charset -moz-document).include?(name)
        super
      end

      def selector_comma_sequence
        sel = selector
        return unless sel
        selectors = [sel]
        ws = ''
        while tok(/,/)
          ws << str {ss}
          next unless (sel = selector)
          selectors << sel
          if ws.include?("\n")
            selectors[-1] = Selector::Sequence.new(["\n"] + selectors.last.members)
          end
          ws = ''
        end
        Selector::CommaSequence.new(selectors)
      end

      def selector_string
        sel = selector
        return unless sel
        sel.to_s
      end

      def selector
        start_pos = source_position
        # The combinator here allows the "> E" hack
        val = combinator || simple_selector_sequence
        return unless val
        nl = str {ss}.include?("\n")
        res = []
        res << val
        res << "\n" if nl

        while (val = combinator || simple_selector_sequence)
          res << val
          res << "\n" if str {ss}.include?("\n")
        end
        seq = Selector::Sequence.new(res.compact)

        if seq.members.any? {|sseq| sseq.is_a?(Selector::SimpleSequence) && sseq.subject?}
          location = " of #{@filename}" if @filename
          Sass::Util.sass_warn <<MESSAGE
DEPRECATION WARNING on line #{start_pos.line}, column #{start_pos.offset}#{location}:
The subject selector operator "!" is deprecated and will be removed in a future release.
This operator has been replaced by ":has()" in the CSS spec.
For example: #{seq.subjectless}
MESSAGE
        end

        seq
      end

      def combinator
        tok(PLUS) || tok(GREATER) || tok(TILDE) || reference_combinator
      end

      def reference_combinator
        return unless tok(%r{/})
        res = '/'
        ns, name = expr!(:qualified_name)
        res << ns << '|' if ns
        res << name << tok!(%r{/})

        location = " of #{@filename}" if @filename
        Sass::Util.sass_warn <<MESSAGE
DEPRECATION WARNING on line #{@line}, column #{@offset}#{location}:
The reference combinator #{res} is deprecated and will be removed in a future release.
MESSAGE

        res
      end

      def simple_selector_sequence
        start_pos = source_position
        e = element_name || id_selector || class_selector || placeholder_selector || attrib ||
            pseudo || parent_selector
        return unless e
        res = [e]

        # The tok(/\*/) allows the "E*" hack
        while (v = id_selector || class_selector || placeholder_selector ||
                   attrib || pseudo || (tok(/\*/) && Selector::Universal.new(nil)))
          res << v
        end

        pos = @scanner.pos
        line = @line
        if (sel = str? {simple_selector_sequence})
          @scanner.pos = pos
          @line = line
          begin
            # If we see "*E", don't force a throw because this could be the
            # "*prop: val" hack.
            expected('"{"') if res.length == 1 && res[0].is_a?(Selector::Universal)
            throw_error {expected('"{"')}
          rescue Sass::SyntaxError => e
            e.message << "\n\n\"#{sel}\" may only be used at the beginning of a compound selector."
            raise e
          end
        end

        Selector::SimpleSequence.new(res, tok(/!/), range(start_pos))
      end

      def parent_selector
        return unless @allow_parent_ref && tok(/&/)
        Selector::Parent.new(name)
      end

      def class_selector
        return unless tok(/\./)
        @expected = "class name"
        Selector::Class.new(ident!)
      end

      def id_selector
        return unless tok(/#(?!\{)/)
        @expected = "id name"
        Selector::Id.new(name!)
      end

      def placeholder_selector
        return unless tok(/%/)
        @expected = "placeholder name"
        Selector::Placeholder.new(ident!)
      end

      def element_name
        ns, name = Sass::Util.destructure(qualified_name(:allow_star_name))
        return unless ns || name

        if name == '*'
          Selector::Universal.new(ns)
        else
          Selector::Element.new(name, ns)
        end
      end

      def qualified_name(allow_star_name = false)
        name = ident || tok(/\*/) || (tok?(/\|/) && "")
        return unless name
        return nil, name unless tok(/\|/)

        return name, ident! unless allow_star_name
        @expected = "identifier or *"
        return name, ident || tok!(/\*/)
      end

      def attrib
        return unless tok(/\[/)
        ss
        ns, name = attrib_name!
        ss

        op = tok(/=/) ||
             tok(INCLUDES) ||
             tok(DASHMATCH) ||
             tok(PREFIXMATCH) ||
             tok(SUFFIXMATCH) ||
             tok(SUBSTRINGMATCH)
        if op
          @expected = "identifier or string"
          ss
          val = ident || tok!(STRING)
          ss
        end
        flags = ident || tok(STRING)
        tok!(/\]/)

        Selector::Attribute.new(name, ns, op, val, flags)
      end

      def attrib_name!
        if (name_or_ns = ident)
          # E, E|E
          if tok(/\|(?!=)/)
            ns = name_or_ns
            name = ident
          else
            name = name_or_ns
          end
        else
          # *|E or |E
          ns = tok(/\*/) || ""
          tok!(/\|/)
          name = ident!
        end
        return ns, name
      end

      SELECTOR_PSEUDO_CLASSES = %w(not matches current any has host host-context).to_set

      PREFIXED_SELECTOR_PSEUDO_CLASSES = %w(nth-child nth-last-child).to_set

      SELECTOR_PSEUDO_ELEMENTS = %w(slotted).to_set

      def pseudo
        s = tok(/::?/)
        return unless s
        @expected = "pseudoclass or pseudoelement"
        name = ident!
        if tok(/\(/)
          ss
          deprefixed = deprefix(name)
          if s == ':' && SELECTOR_PSEUDO_CLASSES.include?(deprefixed)
            sel = selector_comma_sequence
          elsif s == ':' && PREFIXED_SELECTOR_PSEUDO_CLASSES.include?(deprefixed)
            arg, sel = prefixed_selector_pseudo
          elsif s == '::' && SELECTOR_PSEUDO_ELEMENTS.include?(deprefixed)
            sel = selector_comma_sequence
          else
            arg = expr!(:declaration_value).join
          end

          tok!(/\)/)
        end
        Selector::Pseudo.new(s == ':' ? :class : :element, name, arg, sel)
      end

      def prefixed_selector_pseudo
        prefix = str do
          expr = str {expr!(:a_n_plus_b)}
          ss
          return expr, nil unless tok(/of/)
          ss
        end
        return prefix, expr!(:selector_comma_sequence)
      end

      def a_n_plus_b
        if (parity = tok(/even|odd/i))
          return parity
        end

        if tok(/[+-]?[0-9]+/)
          ss
          return true unless tok(/n/)
        else
          return unless tok(/[+-]?n/i)
        end
        ss

        return true unless tok(/[+-]/)
        ss
        @expected = "number"
        tok!(/[0-9]+/)
        true
      end

      def keyframes_selector
        ss
        str do
          return unless keyframes_selector_component
          ss
          while tok(/,/)
            ss
            expr!(:keyframes_selector_component)
            ss
          end
        end
      end

      def keyframes_selector_component
        ident || tok(PERCENTAGE)
      end

      @sass_script_parser = Class.new(Sass::Script::CssParser)
    end
  end
end
