# frozen_string_literal: true

module Parser
  module Source

    ##
    # {Rewriter} is deprecated. Use {TreeRewriter} instead.
    #
    # TreeRewriter has simplified semantics, and customizable policies
    # with regards to clobbering. Please read the documentation.
    #
    # Keep in mind:
    # - Rewriter was discarding the `end_pos` of the given range for `insert_before`,
    #   and the `begin_pos` for `insert_after`. These are meaningful in TreeRewriter.
    # - TreeRewriter's wrap/insert_before/insert_after are multiple by default, while
    #   Rewriter would raise clobbering errors if the non '_multi' version was called.
    # - The TreeRewriter policy closest to Rewriter's behavior is:
    #       different_replacements: :raise,
    #       swallowed_insertions: :raise,
    #       crossing_deletions: :accept
    #
    # @!attribute [r] source_buffer
    #  @return [Source::Buffer]
    #
    # @!attribute [r] diagnostics
    #  @return [Diagnostic::Engine]
    #
    # @api public
    # @deprecated Use {TreeRewriter}
    #
    class Rewriter
      attr_reader :source_buffer
      attr_reader :diagnostics

      ##
      # @param [Source::Buffer] source_buffer
      # @deprecated Use {TreeRewriter}
      #
      def initialize(source_buffer)
        self.class.warn_of_deprecation
        @diagnostics = Diagnostic::Engine.new
        @diagnostics.consumer = lambda do |diag|
          $stderr.puts diag.render
        end

        @source_buffer = source_buffer
        @queue         = []
        @clobber       = 0
        @insertions    = 0 # clobbered zero-length positions; index 0 is the far left

        @insert_before_multi_order = 0
        @insert_after_multi_order = 0

        @pending_queue = nil
        @pending_clobber = nil
        @pending_insertions = nil
      end

      ##
      # Removes the source range.
      #
      # @param [Range] range
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      # @deprecated Use {TreeRewriter#remove}
      #
      def remove(range)
        append Rewriter::Action.new(range, ''.freeze)
      end

      ##
      # Inserts new code before the given source range.
      #
      # @param [Range] range
      # @param [String] content
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      # @deprecated Use {TreeRewriter#insert_before}
      #
      def insert_before(range, content)
        append Rewriter::Action.new(range.begin, content)
      end

      ##
      # Inserts new code before and after the given source range.
      #
      # @param [Range] range
      # @param [String] before
      # @param [String] after
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      # @deprecated Use {TreeRewriter#wrap}
      #
      def wrap(range, before, after)
        append Rewriter::Action.new(range.begin, before)
        append Rewriter::Action.new(range.end, after)
      end

      ##
      # Inserts new code before the given source range by allowing other
      # insertions at the same position.
      # Note that an insertion with latter invocation comes _before_ earlier
      # insertion at the same position in the rewritten source.
      #
      # @example Inserting '[('
      #   rewriter.
      #     insert_before_multi(range, '(').
      #     insert_before_multi(range, '[').
      #     process
      #
      # @param [Range] range
      # @param [String] content
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      # @deprecated Use {TreeRewriter#insert_before}
      #
      def insert_before_multi(range, content)
        @insert_before_multi_order -= 1
        append Rewriter::Action.new(range.begin, content, true, @insert_before_multi_order)
      end

      ##
      # Inserts new code after the given source range.
      #
      # @param [Range] range
      # @param [String] content
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      # @deprecated Use {TreeRewriter#insert_after}
      #
      def insert_after(range, content)
        append Rewriter::Action.new(range.end, content)
      end

      ##
      # Inserts new code after the given source range by allowing other
      # insertions at the same position.
      # Note that an insertion with latter invocation comes _after_ earlier
      # insertion at the same position in the rewritten source.
      #
      # @example Inserting ')]'
      #   rewriter.
      #     insert_after_multi(range, ')').
      #     insert_after_multi(range, ']').
      #     process
      #
      # @param [Range] range
      # @param [String] content
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      # @deprecated Use {TreeRewriter#insert_after}
      #
      def insert_after_multi(range, content)
        @insert_after_multi_order += 1
        append Rewriter::Action.new(range.end, content, true, @insert_after_multi_order)
      end

      ##
      # Replaces the code of the source range `range` with `content`.
      #
      # @param [Range] range
      # @param [String] content
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      # @deprecated Use {TreeRewriter#replace}
      #
      def replace(range, content)
        append Rewriter::Action.new(range, content)
      end

      ##
      # Applies all scheduled changes to the `source_buffer` and returns
      # modified source as a new string.
      #
      # @return [String]
      # @deprecated Use {TreeRewriter#process}
      #
      def process
        if in_transaction?
          raise "Do not call #{self.class}##{__method__} inside a transaction"
        end

        adjustment = 0
        source     = @source_buffer.source.dup

        @queue.sort.each do |action|
          begin_pos = action.range.begin_pos + adjustment
          end_pos   = begin_pos + action.range.length

          source[begin_pos...end_pos] = action.replacement

          adjustment += (action.replacement.length - action.range.length)
        end

        source
      end

      ##
      # Provides a protected block where a sequence of multiple rewrite actions
      # are handled atomically. If any of the actions failed by clobbering,
      # all the actions are rolled back.
      #
      # @example
      #  begin
      #    rewriter.transaction do
      #      rewriter.insert_before(range_of_something, '(')
      #      rewriter.insert_after(range_of_something, ')')
      #    end
      #  rescue Parser::ClobberingError
      #  end
      #
      # @raise [RuntimeError] when no block is passed
      # @raise [RuntimeError] when already in a transaction
      # @deprecated Use {TreeRewriter#transaction}
      #
      def transaction
        unless block_given?
          raise "#{self.class}##{__method__} requires block"
        end

        if in_transaction?
          raise 'Nested transaction is not supported'
        end

        @pending_queue = @queue.dup
        @pending_clobber = @clobber
        @pending_insertions = @insertions

        yield

        @queue = @pending_queue
        @clobber = @pending_clobber
        @insertions = @pending_insertions

        self
      ensure
        @pending_queue = nil
        @pending_clobber = nil
        @pending_insertions = nil
      end

      private

      # Schedule a code update. If it overlaps with another update, check
      # whether they conflict, and raise a clobbering error if they do.
      # (As a special case, zero-length ranges at the same position are
      # considered to "overlap".) Otherwise, merge them.
      #
      # Updates which are adjacent to each other, but do not overlap, are also
      # merged.
      #
      # RULES:
      #
      # - Insertion ("replacing" a zero-length range):
      #   - Two insertions at the same point conflict. This is true even
      #     if the earlier insertion has already been merged with an adjacent
      #     update, and even if they are both inserting the same text.
      #   - An insertion never conflicts with a replace or remove operation
      #     on its right or left side, which does not overlap it (in other
      #     words, which does not update BOTH its right and left sides).
      #   - An insertion always conflicts with a remove operation which spans
      #     both its sides.
      #   - An insertion conflicts with a replace operation which spans both its
      #     sides, unless the replacement text is longer than the replaced text
      #     by the size of the insertion (or more), and the portion of
      #     replacement text immediately after the insertion position is
      #     identical to the inserted text.
      #
      # - Removal operations never conflict with each other.
      #
      # - Replacement operations:
      #   - Take the portion of each replacement text which falls within:
      #     - The other operation's replaced region
      #     - The other operation's replacement text, if it extends past the
      #       end of its own replaced region (in other words, if the replacement
      #       text is longer than the text it replaces)
      #   - If and only if the taken texts are identical for both operations,
      #     they do not conflict.
      #
      def append(action)
        range = action.range

        # Is this an insertion?
        if range.empty?
          # Replacing nothing with... nothing?
          return self if action.replacement.empty?

          if !action.allow_multiple_insertions? && (conflicting = clobbered_insertion?(range))
            raise_clobber_error(action, [conflicting])
          end

          record_insertion(range)

          if (adjacent = adjacent_updates?(range))
            conflicting = adjacent.find do |a|
              a.range.overlaps?(range) &&
                !replace_compatible_with_insertion?(a, action)
            end
            raise_clobber_error(action, [conflicting]) if conflicting

            merge_actions!(action, adjacent)
          else
            active_queue << action
          end
        else
          # It's a replace or remove operation.
          if (insertions = adjacent_insertions?(range))
            insertions.each do |insertion|
              if range.overlaps?(insertion.range) &&
                 !replace_compatible_with_insertion?(action, insertion)
                raise_clobber_error(action, [insertion])
              else
                action = merge_actions(action, [insertion])
                active_queue.delete(insertion)
              end
            end
          end

          if (adjacent = adjacent_updates?(range))
            if can_merge?(action, adjacent)
              record_replace(range)
              merge_actions!(action, adjacent)
            else
              raise_clobber_error(action, adjacent)
            end
          else
            record_replace(range)
            active_queue << action
          end
        end

        self
      end

      def record_insertion(range)
        self.active_insertions = active_insertions | (1 << range.begin_pos)
      end

      def record_replace(range)
        self.active_clobber = active_clobber | clobbered_position_mask(range)
      end

      def clobbered_position_mask(range)
        ((1 << range.size) - 1) << range.begin_pos
      end

      def adjacent_position_mask(range)
        ((1 << (range.size + 2)) - 1) << (range.begin_pos - 1)
      end

      def adjacent_insertion_mask(range)
        ((1 << (range.size + 1)) - 1) << range.begin_pos
      end

      def clobbered_insertion?(insertion)
        insertion_pos = insertion.begin_pos
        if active_insertions & (1 << insertion_pos) != 0
          # The clobbered insertion may have already been merged with other
          # updates, so it won't necessarily have the same begin_pos.
          active_queue.find do |a|
            a.range.begin_pos <= insertion_pos && insertion_pos <= a.range.end_pos
          end
        end
      end

      def adjacent_insertions?(range)
        # Just retrieve insertions which have not been merged with an adjacent
        # remove or replace.
        if active_insertions & adjacent_insertion_mask(range) != 0
          result = active_queue.select do |a|
            a.range.empty? && adjacent?(range, a.range)
          end
          result.empty? ? nil : result
        end
      end

      def adjacent_updates?(range)
        if active_clobber & adjacent_position_mask(range) != 0
          active_queue.select { |a| adjacent?(range, a.range) }
        end
      end

      def replace_compatible_with_insertion?(replace, insertion)
        (replace.replacement.length - replace.range.size) >= insertion.range.size &&
          (offset = insertion.range.begin_pos - replace.range.begin_pos) &&
          replace.replacement[offset, insertion.replacement.length] == insertion.replacement
      end

      def can_merge?(action, existing)
        # Compare 2 replace/remove operations (neither is an insertion)
        range = action.range

        existing.all? do |other|
          overlap = range.intersect(other.range)
          next true if overlap.nil? # adjacent, not overlapping

          repl1_offset = overlap.begin_pos - range.begin_pos
          repl2_offset = overlap.begin_pos - other.range.begin_pos
          repl1_length = [other.range.length - repl2_offset,
                          other.replacement.length  - repl2_offset].max
          repl2_length = [range.length - repl1_offset,
                          action.replacement.length - repl1_offset].max

          replacement1 = action.replacement[repl1_offset, repl1_length] || ''.freeze
          replacement2 = other.replacement[repl2_offset, repl2_length] || ''.freeze
          replacement1 == replacement2
        end
      end

      def merge_actions(action, existing)
        actions = existing.push(action).sort_by do |a|
          [a.range.begin_pos, a.range.end_pos]
        end
        range = actions.first.range.join(actions.max_by { |a| a.range.end_pos }.range)

        Rewriter::Action.new(range, merge_replacements(actions))
      end

      def merge_actions!(action, existing)
        new_action = merge_actions(action, existing)
        active_queue.delete(action)
        replace_actions(existing, new_action)
      end

      def merge_replacements(actions)
        result    = ''.dup
        prev_act  = nil

        actions.each do |act|
          if !prev_act || act.range.disjoint?(prev_act.range)
            result << act.replacement
          else
            prev_end = [prev_act.range.begin_pos + prev_act.replacement.length,
                        prev_act.range.end_pos].max
            offset   = prev_end - act.range.begin_pos
            result << act.replacement[offset..-1] if offset < act.replacement.size
          end

          prev_act = act
        end

        result
      end

      def replace_actions(old, updated)
        old.each { |act| active_queue.delete(act) }
        active_queue << updated
      end

      def raise_clobber_error(action, existing)
        # cannot replace 3 characters with "foobar"
        diagnostic = Diagnostic.new(:error,
                                    :invalid_action,
                                    { :action => action },
                                    action.range)
        @diagnostics.process(diagnostic)

        # clobbered by: remove 3 characters
        diagnostic = Diagnostic.new(:note,
                                    :clobbered,
                                    { :action => existing[0] },
                                    existing[0].range)
        @diagnostics.process(diagnostic)

        raise ClobberingError, "Parser::Source::Rewriter detected clobbering"
      end

      def in_transaction?
        !@pending_queue.nil?
      end

      def active_queue
        @pending_queue || @queue
      end

      def active_clobber
        @pending_clobber || @clobber
      end

      def active_insertions
        @pending_insertions || @insertions
      end

      def active_clobber=(value)
        if @pending_clobber
          @pending_clobber = value
        else
          @clobber = value
        end
      end

      def active_insertions=(value)
        if @pending_insertions
          @pending_insertions = value
        else
          @insertions = value
        end
      end

      def adjacent?(range1, range2)
        range1.begin_pos <= range2.end_pos && range2.begin_pos <= range1.end_pos
      end

      DEPRECATION_WARNING = [
        'Parser::Source::Rewriter is deprecated.',
        'Please update your code to use Parser::Source::TreeRewriter instead'
      ].join("\n").freeze

      extend Deprecation
    end

  end
end
