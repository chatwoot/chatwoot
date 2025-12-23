# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for places where a subset of an Enumerable (array,
      # range, set, etc.; see note below) is calculated based on a `Regexp`
      # match, and suggests `grep` or `grep_v` instead.
      #
      # NOTE: Hashes do not behave as you may expect with `grep`, which
      # means that `hash.grep` is not equivalent to `hash.select`. Although
      # RuboCop is limited by static analysis, this cop attempts to avoid
      # registering an offense when the receiver is a hash (hash literal,
      # `Hash.new`, `Hash#[]`, or `to_h`/`to_hash`).
      #
      # NOTE: `grep` and `grep_v` were optimized when used without a block
      # in Ruby 3.0, but may be slower in previous versions.
      # See https://bugs.ruby-lang.org/issues/17030
      #
      # @safety
      #   Autocorrection is marked as unsafe because `MatchData` will
      #   not be created by `grep`, but may have previously been relied
      #   upon after the `match?` or `=~` call.
      #
      #   Additionally, the cop cannot guarantee that the receiver of
      #   `select` or `reject` is actually an array by static analysis,
      #   so the correction may not be actually equivalent.
      #
      # @example
      #   # bad (select, filter, or find_all)
      #   array.select { |x| x.match? /regexp/ }
      #   array.select { |x| /regexp/.match?(x) }
      #   array.select { |x| x =~ /regexp/ }
      #   array.select { |x| /regexp/ =~ x }
      #
      #   # bad (reject)
      #   array.reject { |x| x.match? /regexp/ }
      #   array.reject { |x| /regexp/.match?(x) }
      #   array.reject { |x| x =~ /regexp/ }
      #   array.reject { |x| /regexp/ =~ x }
      #
      #   # good
      #   array.grep(regexp)
      #   array.grep_v(regexp)
      class SelectByRegexp < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Prefer `%<replacement>s` to `%<original_method>s` with a regexp match.'
        RESTRICT_ON_SEND = %i[select filter find_all reject].freeze
        REPLACEMENTS = { select: 'grep', filter: 'grep', find_all: 'grep', reject: 'grep_v' }.freeze
        OPPOSITE_REPLACEMENTS = {
          select: 'grep_v', filter: 'grep_v', find_all: 'grep_v', reject: 'grep'
        }.freeze
        REGEXP_METHODS = %i[match? =~ !~].to_set.freeze

        # @!method regexp_match?(node)
        def_node_matcher :regexp_match?, <<~PATTERN
          {
            (block call (args (arg $_)) ${(send _ %REGEXP_METHODS _) match-with-lvasgn})
            (numblock call $1 ${(send _ %REGEXP_METHODS _) match-with-lvasgn})
            (itblock call $_ ${(send _ %REGEXP_METHODS _) match-with-lvasgn})
          }
        PATTERN

        # Returns true if a node appears to return a hash
        # @!method creates_hash?(node)
        def_node_matcher :creates_hash?, <<~PATTERN
          {
            (call (const _ :Hash) {:new :[]} ...)
            (block (call (const _ :Hash) :new ...) ...)
            (call _ { :to_h :to_hash } ...)
          }
        PATTERN

        # @!method env_const?(node)
        def_node_matcher :env_const?, <<~PATTERN
          (const {nil? cbase} :ENV)
        PATTERN

        # @!method calls_lvar?(node, name)
        def_node_matcher :calls_lvar?, <<~PATTERN
          {
            (send (lvar %1) ...)
            (send ... (lvar %1))
            (match-with-lvasgn regexp (lvar %1))
          }
        PATTERN

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def on_send(node)
          return if target_ruby_version < 2.6 && node.method?(:filter)
          return unless (block_node = node.block_node)
          return if block_node.body&.begin_type?
          return if receiver_allowed?(block_node.receiver)
          return unless (regexp_method_send_node = extract_send_node(block_node))
          return if match_predicate_without_receiver?(regexp_method_send_node)

          replacement = replacement(regexp_method_send_node, node)
          return if target_ruby_version <= 2.2 && replacement == 'grep_v'

          regexp = find_regexp(regexp_method_send_node, block_node)

          register_offense(node, block_node, regexp, replacement)
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        alias on_csend on_send

        private

        def receiver_allowed?(node)
          return false unless node

          node.hash_type? || creates_hash?(node) || env_const?(node)
        end

        def replacement(regexp_method_send_node, node)
          opposite = opposite?(regexp_method_send_node)

          method_name = node.method_name

          opposite ? OPPOSITE_REPLACEMENTS[method_name] : REPLACEMENTS[method_name]
        end

        def register_offense(node, block_node, regexp, replacement)
          message = format(MSG, replacement: replacement, original_method: node.method_name)

          add_offense(block_node, message: message) do |corrector|
            # Only correct if it can be determined what the regexp is
            if regexp
              range = range_between(node.loc.selector.begin_pos, block_node.loc.end.end_pos)
              corrector.replace(range, "#{replacement}(#{regexp.source})")
            end
          end
        end

        def extract_send_node(block_node)
          return unless (block_arg_name, regexp_method_send_node = regexp_match?(block_node))

          block_arg_name = :"_#{block_arg_name}" if block_node.numblock_type?

          return unless calls_lvar?(regexp_method_send_node, block_arg_name)

          regexp_method_send_node
        end

        def opposite?(regexp_method_send_node)
          regexp_method_send_node.send_type? && regexp_method_send_node.method?(:!~)
        end

        def find_regexp(node, block)
          return node.child_nodes.first if node.match_with_lvasgn_type?

          if node.receiver.lvar_type? &&
             (block.type?(:numblock, :itblock) ||
              node.receiver.source == block.first_argument.source)
            node.first_argument
          elsif node.first_argument.lvar_type?
            node.receiver
          end
        end

        def match_predicate_without_receiver?(node)
          node.send_type? && node.method?(:match?) && node.receiver.nil?
        end
      end
    end
  end
end
