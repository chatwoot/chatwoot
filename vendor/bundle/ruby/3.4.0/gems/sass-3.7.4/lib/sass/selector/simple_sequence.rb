module Sass
  module Selector
    # A unseparated sequence of selectors
    # that all apply to a single element.
    # For example, `.foo#bar[attr=baz]` is a simple sequence
    # of the selectors `.foo`, `#bar`, and `[attr=baz]`.
    class SimpleSequence < AbstractSequence
      # The array of individual selectors.
      #
      # @return [Array<Simple>]
      attr_accessor :members

      # The extending selectors that caused this selector sequence to be
      # generated. For example:
      #
      #     a.foo { ... }
      #     b.bar {@extend a}
      #     c.baz {@extend b}
      #
      # The generated selector `b.foo.bar` has `{b.bar}` as its `sources` set,
      # and the generated selector `c.foo.bar.baz` has `{b.bar, c.baz}` as its
      # `sources` set.
      #
      # This is populated during the {Sequence#do_extend} process.
      #
      # @return {Set<Sequence>}
      attr_accessor :sources

      # This sequence source range.
      #
      # @return [Sass::Source::Range]
      attr_accessor :source_range

      # @see \{#subject?}
      attr_writer :subject

      # Returns the element or universal selector in this sequence,
      # if it exists.
      #
      # @return [Element, Universal, nil]
      def base
        @base ||= (members.first if members.first.is_a?(Element) || members.first.is_a?(Universal))
      end

      def pseudo_elements
        @pseudo_elements ||= members.select {|sel| sel.is_a?(Pseudo) && sel.type == :element}
      end

      def selector_pseudo_classes
        @selector_pseudo_classes ||= members.
          select {|sel| sel.is_a?(Pseudo) && sel.type == :class && sel.selector}.
          group_by {|sel| sel.normalized_name}
      end

      # Returns the non-base, non-pseudo-element selectors in this sequence.
      #
      # @return [Set<Simple>]
      def rest
        @rest ||= Set.new(members - [base] - pseudo_elements)
      end

      # Whether or not this compound selector is the subject of the parent
      # selector; that is, whether it is prepended with `$` and represents the
      # actual element that will be selected.
      #
      # @return [Boolean]
      def subject?
        @subject
      end

      # @param selectors [Array<Simple>] See \{#members}
      # @param subject [Boolean] See \{#subject?}
      # @param source_range [Sass::Source::Range]
      def initialize(selectors, subject, source_range = nil)
        @members = selectors
        @subject = subject
        @sources = Set.new
        @source_range = source_range
      end

      # Resolves the {Parent} selectors within this selector
      # by replacing them with the given parent selector,
      # handling commas appropriately.
      #
      # @param super_cseq [CommaSequence] The parent selector
      # @return [CommaSequence] This selector, with parent references resolved
      # @raise [Sass::SyntaxError] If a parent selector is invalid
      def resolve_parent_refs(super_cseq)
        resolved_members = @members.map do |sel|
          next sel unless sel.is_a?(Pseudo) && sel.selector
          sel.with_selector(sel.selector.resolve_parent_refs(super_cseq, false))
        end.flatten

        # Parent selector only appears as the first selector in the sequence
        unless (parent = resolved_members.first).is_a?(Parent)
          return CommaSequence.new([Sequence.new([SimpleSequence.new(resolved_members, subject?)])])
        end

        return super_cseq if @members.size == 1 && parent.suffix.nil?

        CommaSequence.new(super_cseq.members.map do |super_seq|
          members = super_seq.members.dup
          newline = members.pop if members.last == "\n"
          unless members.last.is_a?(SimpleSequence)
            raise Sass::SyntaxError.new("Invalid parent selector for \"#{self}\": \"" +
              super_seq.to_s + '"')
          end

          parent_sub = members.last.members
          unless parent.suffix.nil?
            parent_sub = parent_sub.dup
            parent_sub[-1] = parent_sub.last.dup
            case parent_sub.last
            when Sass::Selector::Class, Sass::Selector::Id, Sass::Selector::Placeholder
              parent_sub[-1] = parent_sub.last.class.new(parent_sub.last.name + parent.suffix)
            when Sass::Selector::Element
              parent_sub[-1] = parent_sub.last.class.new(
                parent_sub.last.name + parent.suffix,
                parent_sub.last.namespace)
            when Sass::Selector::Pseudo
              if parent_sub.last.arg || parent_sub.last.selector
                raise Sass::SyntaxError.new("Invalid parent selector for \"#{self}\": \"" +
                  super_seq.to_s + '"')
              end
              parent_sub[-1] = Sass::Selector::Pseudo.new(
                parent_sub.last.type,
                parent_sub.last.name + parent.suffix,
                nil, nil)
            else
              raise Sass::SyntaxError.new("Invalid parent selector for \"#{self}\": \"" +
                super_seq.to_s + '"')
            end
          end

          Sequence.new(members[0...-1] +
            [SimpleSequence.new(parent_sub + resolved_members[1..-1], subject?)] +
            [newline].compact)
          end)
      end

      # Non-destructively extends this selector with the extensions specified in a hash
      # (which should come from {Sass::Tree::Visitors::Cssize}).
      #
      # @param extends [{Selector::Simple =>
      #                  Sass::Tree::Visitors::Cssize::Extend}]
      #   The extensions to perform on this selector
      # @param parent_directives [Array<Sass::Tree::DirectiveNode>]
      #   The directives containing this selector.
      # @param seen [Set<Array<Selector::Simple>>]
      #   The set of simple sequences that are currently being replaced.
      # @param original [Boolean]
      #   Whether this is the original selector being extended, as opposed to
      #   the result of a previous extension that's being re-extended.
      # @return [Array<Sequence>] A list of selectors generated
      #   by extending this selector with `extends`.
      # @see CommaSequence#do_extend
      def do_extend(extends, parent_directives, replace, seen)
        seen_with_pseudo_selectors = seen.dup

        modified_original = false
        members = self.members.map do |sel|
          next sel unless sel.is_a?(Pseudo) && sel.selector
          next sel if seen.include?([sel])
          extended = sel.selector.do_extend(extends, parent_directives, replace, seen, false)
          next sel if extended == sel.selector
          extended.members.reject! {|seq| seq.invisible?}

          # For `:not()`, we usually want to get rid of any complex
          # selectors because that will cause the selector to fail to
          # parse on all browsers at time of writing. We can keep them
          # if either the original selector had a complex selector, or
          # the result of extending has only complex selectors,
          # because either way we aren't breaking anything that isn't
          # already broken.
          if sel.normalized_name == 'not' &&
              (sel.selector.members.none? {|seq| seq.members.length > 1} &&
               extended.members.any? {|seq| seq.members.length == 1})
            extended.members.reject! {|seq| seq.members.length > 1}
          end

          modified_original = true
          result = sel.with_selector(extended)
          result.each {|new_sel| seen_with_pseudo_selectors << [new_sel]}
          result
        end.flatten

        groups = extends[members.to_set].group_by {|ex| ex.extender}.to_a
        groups.map! do |seq, group|
          sels = group.map {|e| e.target}.flatten
          # If A {@extend B} and C {...},
          # seq is A, sels is B, and self is C

          self_without_sel = Sass::Util.array_minus(members, sels)
          group.each {|e| e.success = true}
          unified = seq.members.last.unify(SimpleSequence.new(self_without_sel, subject?))
          next unless unified
          group.each {|e| check_directives_match!(e, parent_directives)}
          new_seq = Sequence.new(seq.members[0...-1] + [unified])
          new_seq.add_sources!(sources + [seq])
          [sels, new_seq]
        end
        groups.compact!
        groups.map! do |sels, seq|
          next [] if seen.include?(sels)
          seq.do_extend(
            extends, parent_directives, false, seen_with_pseudo_selectors + [sels], false)
        end
        groups.flatten!

        if modified_original || !replace || groups.empty?
          # First Law of Extend: the result of extending a selector should
          # (almost) always contain the base selector.
          #
          # See https://github.com/nex3/sass/issues/324.
          original = Sequence.new([SimpleSequence.new(members, @subject, source_range)])
          original.add_sources! sources
          groups.unshift original
        end
        groups.uniq!
        groups
      end

      # Unifies this selector with another {SimpleSequence}, returning
      # another `SimpleSequence` that is a subselector of both input
      # selectors.
      #
      # @param other [SimpleSequence]
      # @return [SimpleSequence, nil] A {SimpleSequence} matching both `sels` and this selector,
      #   or `nil` if this is impossible (e.g. unifying `#foo` and `#bar`)
      # @raise [Sass::SyntaxError] If this selector cannot be unified.
      #   This will only ever occur when a dynamic selector,
      #   such as {Parent} or {Interpolation}, is used in unification.
      #   Since these selectors should be resolved
      #   by the time extension and unification happen,
      #   this exception will only ever be raised as a result of programmer error
      def unify(other)
        sseq = members.inject(other.members) do |member, sel|
          return unless member
          sel.unify(member)
        end
        return unless sseq
        SimpleSequence.new(sseq, other.subject? || subject?)
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
        return false unless base.nil? || base.eql?(their_sseq.base)
        return false unless pseudo_elements.eql?(their_sseq.pseudo_elements)
        our_spcs = selector_pseudo_classes
        their_spcs = their_sseq.selector_pseudo_classes

        # Some psuedo-selectors can be subselectors of non-pseudo selectors.
        # Pull those out here so we can efficiently check against them below.
        their_subselector_pseudos = %w(matches any nth-child nth-last-child).
          map {|name| their_spcs[name] || []}.flatten

        # If `self`'s non-pseudo simple selectors aren't a subset of `their_sseq`'s,
        # it's definitely not a superselector. This also considers being matched
        # by `:matches` or `:any`.
        return false unless rest.all? do |our_sel|
          next true if our_sel.is_a?(Pseudo) && our_sel.selector
          next true if their_sseq.rest.include?(our_sel)
          their_subselector_pseudos.any? do |their_pseudo|
            their_pseudo.selector.members.all? do |their_seq|
              next false unless their_seq.members.length == 1
              their_sseq = their_seq.members.first
              next false unless their_sseq.is_a?(SimpleSequence)
              their_sseq.rest.include?(our_sel)
            end
          end
        end

        our_spcs.all? do |_name, pseudos|
          pseudos.all? {|pseudo| pseudo.superselector?(their_sseq, parents)}
        end
      end

      # @see Simple#to_s
      def to_s(opts = {})
        res = @members.map {|m| m.to_s(opts)}.join

        # :not(%foo) may resolve to the empty string, but it should match every
        # selector so we replace it with "*".
        res = '*' if res.empty?

        res << '!' if subject?
        res
      end

      # Returns a string representation of the sequence.
      # This is basically the selector string.
      #
      # @return [String]
      def inspect
        res = members.map {|m| m.inspect}.join
        res << '!' if subject?
        res
      end

      # Return a copy of this simple sequence with `sources` merged into the
      # {SimpleSequence#sources} set.
      #
      # @param sources [Set<Sequence>]
      # @return [SimpleSequence]
      def with_more_sources(sources)
        sseq = dup
        sseq.members = members.dup
        sseq.sources = self.sources | sources
        sseq
      end

      private

      def check_directives_match!(extend, parent_directives)
        dirs1 = extend.directives.map {|d| d.resolved_value}
        dirs2 = parent_directives.map {|d| d.resolved_value}
        return if Sass::Util.subsequence?(dirs1, dirs2)
        line = extend.node.line
        filename = extend.node.filename

        # TODO(nweiz): this should use the Sass stack trace of the extend node,
        # not the selector.
        raise Sass::SyntaxError.new(<<MESSAGE)
You may not @extend an outer selector from within #{extend.directives.last.name}.
You may only @extend selectors within the same directive.
From "@extend #{extend.target.join(', ')}" on line #{line}#{" of #{filename}" if filename}.
MESSAGE
      end

      def _hash
        [base, rest.hash].hash
      end

      def _eql?(other)
        other.base.eql?(base) && other.pseudo_elements == pseudo_elements &&
          other.rest.eql?(rest) && other.subject? == subject?
      end
    end
  end
end
