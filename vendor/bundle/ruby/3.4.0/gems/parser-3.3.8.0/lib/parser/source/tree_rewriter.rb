# frozen_string_literal: true

module Parser
  module Source

    ##
    # {TreeRewriter} performs the heavy lifting in the source rewriting process.
    # It schedules code updates to be performed in the correct order.
    #
    # For simple cases, the resulting source will be obvious.
    #
    # Examples for more complex cases follow. Assume these examples are acting on
    # the source `'puts(:hello, :world)`. The methods #wrap, #remove, etc.
    # receive a Range as first argument; for clarity, examples below use english
    # sentences and a string of raw code instead.
    #
    # ## Overlapping ranges:
    #
    # Any two rewriting actions on overlapping ranges will fail and raise
    # a `ClobberingError`, unless they are both deletions (covered next).
    #
    # * wrap ':hello, ' with '(' and ')'
    # * wrap ', :world' with '(' and ')'
    #  => CloberringError
    #
    # ## Overlapping deletions:
    #
    # * remove ':hello, '
    # * remove ', :world'
    #
    # The overlapping ranges are merged and `':hello, :world'` will be removed.
    # This policy can be changed. `:crossing_deletions` defaults to `:accept`
    # but can be set to `:warn` or `:raise`.
    #
    # ## Multiple actions at the same end points:
    #
    # Results will always be independent on the order they were given.
    # Exception: rewriting actions done on exactly the same range (covered next).
    #
    # Example:
    # * replace ', ' by ' => '
    # * wrap ':hello, :world' with '{' and '}'
    # * replace ':world' with ':everybody'
    # * wrap ':world' with '[', ']'
    #
    # The resulting string will be `'puts({:hello => [:everybody]})'`
    # and this result is independent on the order the instructions were given in.
    #
    # Note that if the two "replace" were given as a single replacement of ', :world'
    # for ' => :everybody', the result would be a `ClobberingError` because of the wrap
    # in square brackets.
    #
    # ## Multiple wraps on same range:
    # * wrap ':hello' with '(' and ')'
    # * wrap ':hello' with '[' and ']'
    #
    # The wraps are combined in order given and results would be `'puts([(:hello)], :world)'`.
    #
    # ## Multiple replacements on same range:
    # * replace ':hello' by ':hi', then
    # * replace ':hello' by ':hey'
    #
    # The replacements are made in the order given, so the latter replacement
    # supersedes the former and ':hello' will be replaced by ':hey'.
    #
    # This policy can be changed. `:different_replacements` defaults to `:accept`
    # but can be set to `:warn` or `:raise`.
    #
    # ## Swallowed insertions:
    # wrap 'world' by '__', '__'
    # replace ':hello, :world' with ':hi'
    #
    # A containing replacement will swallow the contained rewriting actions
    # and `':hello, :world'` will be replaced by `':hi'`.
    #
    # This policy can be changed for swallowed insertions. `:swallowed_insertions`
    # defaults to `:accept` but can be set to `:warn` or `:raise`
    #
    # ## Implementation
    # The updates are organized in a tree, according to the ranges they act on
    # (where children are strictly contained by their parent), hence the name.
    #
    # @!attribute [r] source_buffer
    #  @return [Source::Buffer]
    #
    # @!attribute [r] diagnostics
    #  @return [Diagnostic::Engine]
    #
    # @api public
    #
    class TreeRewriter
      attr_reader :source_buffer
      attr_reader :diagnostics

      ##
      # @param [Source::Buffer] source_buffer
      #
      def initialize(source_buffer,
                     crossing_deletions: :accept,
                     different_replacements: :accept,
                     swallowed_insertions: :accept)
        @diagnostics = Diagnostic::Engine.new
        @diagnostics.consumer = -> diag { $stderr.puts diag.render }

        @source_buffer = source_buffer
        @in_transaction = false

        @policy = {crossing_deletions: crossing_deletions,
                   different_replacements: different_replacements,
                   swallowed_insertions: swallowed_insertions}.freeze
        check_policy_validity

        @enforcer = method(:enforce_policy)
        # We need a range that would be jugded as containing all other ranges,
        # including 0...0 and size...size:
        all_encompassing_range = @source_buffer.source_range.adjust(begin_pos: -1, end_pos: +1)
        @action_root = TreeRewriter::Action.new(all_encompassing_range, @enforcer)
      end

      ##
      # Returns true iff no (non trivial) update has been recorded
      #
      # @return [Boolean]
      #
      def empty?
        @action_root.empty?
      end

      ##
      # Merges the updates of argument with the receiver.
      # Policies of the receiver are used.
      # This action is atomic in that it won't change the receiver
      # unless it succeeds.
      #
      # @param [Rewriter] with
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      #
      def merge!(with)
        raise 'TreeRewriter are not for the same source_buffer' unless
          source_buffer == with.source_buffer

        @action_root = @action_root.combine(with.action_root)
        self
      end

      ##
      # Returns a new rewriter that consists of the updates of the received
      # and the given argument. Policies of the receiver are used.
      #
      # @param [Rewriter] with
      # @return [Rewriter] merge of receiver and argument
      # @raise [ClobberingError] when clobbering is detected
      #
      def merge(with)
        dup.merge!(with)
      end

      ##
      # For special cases where one needs to merge a rewriter attached to a different source_buffer
      # or that needs to be offset. Policies of the receiver are used.
      #
      # @param [TreeRewriter] rewriter from different source_buffer
      # @param [Integer] offset
      # @return [Rewriter] self
      # @raise [IndexError] if action ranges (once offset) don't fit the current buffer
      #
      def import!(foreign_rewriter, offset: 0)
        return self if foreign_rewriter.empty?

        contracted = foreign_rewriter.action_root.contract
        merge_effective_range = ::Parser::Source::Range.new(
          @source_buffer,
          contracted.range.begin_pos + offset,
          contracted.range.end_pos + offset,
        )
        check_range_validity(merge_effective_range)

        merge_with = contracted.moved(@source_buffer, offset)

        @action_root = @action_root.combine(merge_with)
        self
      end

      ##
      # Replaces the code of the source range `range` with `content`.
      #
      # @param [Range] range
      # @param [String] content
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      #
      def replace(range, content)
        combine(range, replacement: content)
      end

      ##
      # Inserts the given strings before and after the given range.
      #
      # @param [Range] range
      # @param [String, nil] insert_before
      # @param [String, nil] insert_after
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      #
      def wrap(range, insert_before, insert_after)
        combine(range, insert_before: insert_before.to_s, insert_after: insert_after.to_s)
      end

      ##
      # Shortcut for `replace(range, '')`
      #
      # @param [Range] range
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      #
      def remove(range)
        replace(range, ''.freeze)
      end


      ##
      # Shortcut for `wrap(range, content, nil)`
      #
      # @param [Range] range
      # @param [String] content
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      #
      def insert_before(range, content)
        wrap(range, content, nil)
      end

      ##
      # Shortcut for `wrap(range, nil, content)`
      #
      # @param [Range] range
      # @param [String] content
      # @return [Rewriter] self
      # @raise [ClobberingError] when clobbering is detected
      #
      def insert_after(range, content)
        wrap(range, nil, content)
      end

      ##
      # Applies all scheduled changes to the `source_buffer` and returns
      # modified source as a new string.
      #
      # @return [String]
      #
      def process
        source     = @source_buffer.source

        chunks = []
        last_end = 0
        @action_root.ordered_replacements.each do |range, replacement|
          chunks << source[last_end...range.begin_pos] << replacement
          last_end = range.end_pos
        end
        chunks << source[last_end...source.length]
        chunks.join
      end

      ##
      # Returns a representation of the rewriter as an ordered list of replacements.
      #
      #     rewriter.as_replacements # => [ [1...1, '('],
      #                                     [2...4, 'foo'],
      #                                     [5...6, ''],
      #                                     [6...6, '!'],
      #                                     [10...10, ')'],
      #                                   ]
      #
      # This representation is sufficient to recreate the result of `process` but it is
      # not sufficient to recreate completely the rewriter for further merging/actions.
      # See `as_nested_actions`
      #
      # @return [Array<Range, String>] an ordered list of pairs of range & replacement
      #
      def as_replacements
        @action_root.ordered_replacements
      end

      ##
      # Returns a representation of the rewriter as nested insertions (:wrap) and replacements.
      #
      #     rewriter.as_actions # =>[ [:wrap, 1...10, '(', ')'],
      #                               [:wrap, 2...6, '', '!'],  # aka "insert_after"
      #                               [:replace, 2...4, 'foo'],
      #                               [:replace, 5...6, ''],  # aka "removal"
      #                             ],
      #
      # Contrary to `as_replacements`, this representation is sufficient to recreate exactly
      # the rewriter.
      #
      # @return [Array<(Symbol, Range, String{, String})>]
      #
      def as_nested_actions
        @action_root.nested_actions
      end

      ##
      # Provides a protected block where a sequence of multiple rewrite actions
      # are handled atomically. If any of the actions failed by clobbering,
      # all the actions are rolled back. Transactions can be nested.
      #
      # @raise [RuntimeError] when no block is passed
      #
      def transaction
        unless block_given?
          raise "#{self.class}##{__method__} requires block"
        end

        previous = @in_transaction
        @in_transaction = true
        restore_root = @action_root

        yield

        restore_root = nil

        self
      ensure
        @action_root = restore_root if restore_root
        @in_transaction = previous
      end

      def in_transaction?
        @in_transaction
      end

      # :nodoc:
      def inspect
        "#<#{self.class} #{source_buffer.name}: #{action_summary}>"
      end

      ##
      # @api private
      # @deprecated Use insert_after or wrap
      #
      def insert_before_multi(range, text)
        self.class.warn_of_deprecation
        insert_before(range, text)
      end

      ##
      # @api private
      # @deprecated Use insert_after or wrap
      #
      def insert_after_multi(range, text)
        self.class.warn_of_deprecation
        insert_after(range, text)
      end

      DEPRECATION_WARNING = [
        'TreeRewriter#insert_before_multi and insert_before_multi exist only for legacy compatibility.',
        'Please update your code to use `wrap`, `insert_before` or `insert_after` instead.'
      ].join("\n").freeze

      extend Deprecation

      protected

      attr_reader :action_root

      private

      def action_summary
        replacements = as_replacements
        case replacements.size
        when 0 then return 'empty'
        when 1..3 then #ok
        else
          replacements = replacements.first(3)
          suffix = '…'
        end
        parts = replacements.map do |(range, str)|
          if str.empty? # is this a deletion?
            "-#{range.to_range}"
          elsif range.size == 0 # is this an insertion?
            "+#{str.inspect}@#{range.begin_pos}"
          else # it is a replacement
            "^#{str.inspect}@#{range.to_range}"
          end
        end
        parts << suffix if suffix
        parts.join(', ')
      end

      ACTIONS = %i[accept warn raise].freeze
      def check_policy_validity
        invalid = @policy.values - ACTIONS
        raise ArgumentError, "Invalid policy: #{invalid.join(', ')}" unless invalid.empty?
      end

      def combine(range, attributes)
        range = check_range_validity(range)
        action = TreeRewriter::Action.new(range, @enforcer, **attributes)
        @action_root = @action_root.combine(action)
        self
      end

      def check_range_validity(range)
        if range.begin_pos < 0 || range.end_pos > @source_buffer.source.size
          raise IndexError, "The range #{range.to_range} is outside the bounds of the source"
        end
        range
      end

      def enforce_policy(event)
        return if @policy[event] == :accept
        return unless (values = yield)
        trigger_policy(event, **values)
      end

      POLICY_TO_LEVEL = {warn: :warning, raise: :error}.freeze
      def trigger_policy(event, range: raise, conflict: nil, **arguments)
        action = @policy[event] || :raise
        diag = Parser::Diagnostic.new(POLICY_TO_LEVEL[action], event, arguments, range)
        @diagnostics.process(diag)
        if conflict
          range, *highlights = conflict
          diag = Parser::Diagnostic.new(POLICY_TO_LEVEL[action], :"#{event}_conflict", arguments, range, highlights)
          @diagnostics.process(diag)
        end
        raise Parser::ClobberingError, "Parser::Source::TreeRewriter detected clobbering" if action == :raise
      end
    end
  end
end
