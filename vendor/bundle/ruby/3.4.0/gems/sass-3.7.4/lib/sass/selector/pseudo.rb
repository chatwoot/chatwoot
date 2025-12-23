# coding: utf-8
module Sass
  module Selector
    # A pseudoclass (e.g. `:visited`) or pseudoelement (e.g. `::first-line`)
    # selector. It can have arguments (e.g. `:nth-child(2n+1)`) which can
    # contain selectors (e.g. `:nth-child(2n+1 of .foo)`).
    class Pseudo < Simple
      # Some pseudo-class-syntax selectors are actually considered
      # pseudo-elements and must be treated differently. This is a list of such
      # selectors.
      #
      # @return [Set<String>]
      ACTUALLY_ELEMENTS = %w(after before first-line first-letter).to_set

      # Like \{#type}, but returns the type of selector this looks like, rather
      # than the type it is semantically. This only differs from type for
      # selectors in \{ACTUALLY\_ELEMENTS}.
      #
      # @return [Symbol]
      attr_reader :syntactic_type

      # The name of the selector.
      #
      # @return [String]
      attr_reader :name

      # The argument to the selector,
      # or `nil` if no argument was given.
      #
      # @return [String, nil]
      attr_reader :arg

      # The selector argument, or `nil` if no selector exists.
      #
      # If this and \{#arg\} are both set, \{#arg\} is considered a non-selector
      # prefix.
      #
      # @return [CommaSequence]
      attr_reader :selector

      # @param syntactic_type [Symbol] See \{#syntactic_type}
      # @param name [String] See \{#name}
      # @param arg [nil, String] See \{#arg}
      # @param selector [nil, CommaSequence] See \{#selector}
      def initialize(syntactic_type, name, arg, selector)
        @syntactic_type = syntactic_type
        @name = name
        @arg = arg
        @selector = selector
      end

      def unique?
        type == :class && normalized_name == 'root'
      end

      # Whether or not this selector should be hidden due to containing a
      # placeholder.
      def invisible?
        # :not() is a special case—if you eliminate all the placeholders from
        # it, it should match anything.
        name != 'not' && @selector && @selector.members.all? {|s| s.invisible?}
      end

      # Returns a copy of this with \{#selector} set to \{#new\_selector}.
      #
      # @param new_selector [CommaSequence]
      # @return [Array<Simple>]
      def with_selector(new_selector)
        result = Pseudo.new(syntactic_type, name, arg,
          CommaSequence.new(new_selector.members.map do |seq|
            next seq unless seq.members.length == 1
            sseq = seq.members.first
            next seq unless sseq.is_a?(SimpleSequence) && sseq.members.length == 1
            sel = sseq.members.first
            next seq unless sel.is_a?(Pseudo) && sel.selector

            case normalized_name
            when 'not'
              # In theory, if there's a nested :not its contents should be
              # unified with the return value. For example, if :not(.foo)
              # extends .bar, :not(.bar) should become .foo:not(.bar). However,
              # this is a narrow edge case and supporting it properly would make
              # this code and the code calling it a lot more complicated, so
              # it's not supported for now.
              next [] unless sel.normalized_name == 'matches'
              sel.selector.members
            when 'matches', 'any', 'current', 'nth-child', 'nth-last-child'
              # As above, we could theoretically support :not within :matches, but
              # doing so would require this method and its callers to handle much
              # more complex cases that likely aren't worth the pain.
              next [] unless sel.name == name && sel.arg == arg
              sel.selector.members
            when 'has', 'host', 'host-context', 'slotted'
              # We can't expand nested selectors here, because each layer adds an
              # additional layer of semantics. For example, `:has(:has(img))`
              # doesn't match `<div><img></div>` but `:has(img)` does.
              sel
            else
              []
            end
          end.flatten))

        # Older browsers support :not but only with a single complex selector.
        # In order to support those browsers, we break up the contents of a :not
        # unless it originally contained a selector list.
        return [result] unless normalized_name == 'not'
        return [result] if selector.members.length > 1
        result.selector.members.map do |seq|
          Pseudo.new(syntactic_type, name, arg, CommaSequence.new([seq]))
        end
      end

      # The type of the selector. `:class` if this is a pseudoclass selector,
      # `:element` if it's a pseudoelement.
      #
      # @return [Symbol]
      def type
        ACTUALLY_ELEMENTS.include?(normalized_name) ? :element : syntactic_type
      end

      # Like \{#name\}, but without any vendor prefix.
      #
      # @return [String]
      def normalized_name
        @normalized_name ||= name.gsub(/^-[a-zA-Z0-9]+-/, '')
      end

      # @see Selector#to_s
      def to_s(opts = {})
        # :not() is a special case, because :not(<nothing>) should match
        # everything.
        return '' if name == 'not' && @selector && @selector.members.all? {|m| m.invisible?}

        res = (syntactic_type == :class ? ":" : "::") + @name
        if @arg || @selector
          res << "("
          res << Sass::Util.strip_except_escapes(@arg) if @arg
          res << " " if @arg && @selector
          res << @selector.to_s(opts) if @selector
          res << ")"
        end
        res
      end

      # Returns `nil` if this is a pseudoelement selector
      # and `sels` contains a pseudoelement selector different than this one.
      #
      # @see SimpleSequence#unify
      def unify(sels)
        return if type == :element && sels.any? do |sel|
          sel.is_a?(Pseudo) && sel.type == :element &&
            (sel.name != name || sel.arg != arg || sel.selector != selector)
        end
        super
      end

      # Returns whether or not this selector matches all elements
      # that the given selector matches (as well as possibly more).
      #
      # @example
      #   (.foo).superselector?(.foo.bar) #=> true
      #   (.foo).superselector?(.bar) #=> false
      # @param their_sseq [SimpleSequence]
      # @param parents [Array<SimpleSequence, String>] The parent selectors of `their_sseq`, if any.
      # @return [Boolean]
      def superselector?(their_sseq, parents = [])
        case normalized_name
        when 'matches', 'any'
          # :matches can be a superselector of another selector in one of two
          # ways. Either its constituent selectors can be a superset of those of
          # another :matches in the other selector, or any of its constituent
          # selectors can individually be a superselector of the other selector.
          (their_sseq.selector_pseudo_classes[normalized_name] || []).any? do |their_sel|
            next false unless their_sel.is_a?(Pseudo)
            next false unless their_sel.name == name
            selector.superselector?(their_sel.selector)
          end || selector.members.any? do |our_seq|
            their_seq = Sequence.new(parents + [their_sseq])
            our_seq.superselector?(their_seq)
          end
        when 'has', 'host', 'host-context', 'slotted'
          # Like :matches, :has (et al) can be a superselector of another
          # selector if its constituent selectors are a superset of those of
          # another :has in the other selector. However, the :matches other case
          # doesn't work, because :has refers to nested elements.
          (their_sseq.selector_pseudo_classes[normalized_name] || []).any? do |their_sel|
            next false unless their_sel.is_a?(Pseudo)
            next false unless their_sel.name == name
            selector.superselector?(their_sel.selector)
          end
        when 'not'
          selector.members.all? do |our_seq|
            their_sseq.members.any? do |their_sel|
              if their_sel.is_a?(Element) || their_sel.is_a?(Id)
                # `:not(a)` is a superselector of `h1` and `:not(#foo)` is a
                # superselector of `#bar`.
                our_sseq = our_seq.members.last
                next false unless our_sseq.is_a?(SimpleSequence)
                our_sseq.members.any? do |our_sel|
                  our_sel.class == their_sel.class && our_sel != their_sel
                end
              else
                next false unless their_sel.is_a?(Pseudo)
                next false unless their_sel.name == name
                # :not(X) is a superselector of :not(Y) exactly when Y is a
                # superselector of X.
                their_sel.selector.superselector?(CommaSequence.new([our_seq]))
              end
            end
          end
        when 'current'
          (their_sseq.selector_pseudo_classes['current'] || []).any? do |their_current|
            next false if their_current.name != name
            # Explicitly don't check for nested superselector relationships
            # here. :current(.foo) isn't always a superselector of
            # :current(.foo.bar), since it matches the *innermost* ancestor of
            # the current element that matches the selector. For example:
            #
            #     <div class="foo bar">
            #       <p class="foo">
            #         <span>current element</span>
            #       </p>
            #     </div>
            #
            # Here :current(.foo) would match the p element and *not* the div
            # element, whereas :current(.foo.bar) would match the div and not
            # the p.
            selector == their_current.selector
          end
        when 'nth-child', 'nth-last-child'
          their_sseq.members.any? do |their_sel|
            # This misses a few edge cases. For example, `:nth-child(n of X)`
            # is a superselector of `X`, and `:nth-child(2n of X)` is a
            # superselector of `:nth-child(4n of X)`. These seem rare enough
            # not to be worth worrying about, though.
            next false unless their_sel.is_a?(Pseudo)
            next false unless their_sel.name == name
            next false unless their_sel.arg == arg
            selector.superselector?(their_sel.selector)
          end
        else
          throw "[BUG] Unknown selector pseudo class #{name}"
        end
      end

      # @see AbstractSequence#specificity
      def specificity
        return 1 if type == :element
        return SPECIFICITY_BASE unless selector
        @specificity ||=
          if normalized_name == 'not'
            min = 0
            max = 0
            selector.members.each do |seq|
              spec = seq.specificity
              if spec.is_a?(Range)
                min = Sass::Util.max(spec.begin, min)
                max = Sass::Util.max(spec.end, max)
              else
                min = Sass::Util.max(spec, min)
                max = Sass::Util.max(spec, max)
              end
            end
            min == max ? max : (min..max)
          else
            min = 0
            max = 0
            selector.members.each do |seq|
              spec = seq.specificity
              if spec.is_a?(Range)
                min = Sass::Util.min(spec.begin, min)
                max = Sass::Util.max(spec.end, max)
              else
                min = Sass::Util.min(spec, min)
                max = Sass::Util.max(spec, max)
              end
            end
            min == max ? max : (min..max)
          end
      end
    end
  end
end
