# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # In Ruby 2.7, arguments forwarding has been added.
      #
      # This cop identifies places where `do_something(*args, &block)`
      # can be replaced by `do_something(...)`.
      #
      # In Ruby 3.1, anonymous block forwarding has been added.
      #
      # This cop identifies places where `do_something(&block)` can be replaced
      # by `do_something(&)`; if desired, this functionality can be disabled
      # by setting `UseAnonymousForwarding: false`.
      #
      # In Ruby 3.2, anonymous args/kwargs forwarding has been added.
      #
      # This cop also identifies places where `+use_args(*args)+`/`+use_kwargs(**kwargs)+` can be
      # replaced by `+use_args(*)+`/`+use_kwargs(**)+`; if desired, this functionality can be
      # disabled by setting `UseAnonymousForwarding: false`.
      #
      # And this cop has `RedundantRestArgumentNames`, `RedundantKeywordRestArgumentNames`,
      # and `RedundantBlockArgumentNames` options. This configuration is a list of redundant names
      # that are sufficient for anonymizing meaningless naming.
      #
      # Meaningless names that are commonly used can be anonymized by default:
      # e.g., `+*args+`, `+**options+`, `&block`, and so on.
      #
      # Names not on this list are likely to be meaningful and are allowed by default.
      #
      # This cop handles not only method forwarding but also forwarding to `super`.
      #
      # [NOTE]
      # ====
      # Because of a bug in Ruby 3.3.0, when a block is referenced inside of another block,
      # no offense will be registered until Ruby 3.4:
      #
      # [source,ruby]
      # ----
      # def foo(&block)
      #   # Using an anonymous block would be a syntax error on Ruby 3.3.0
      #   block_method { bar(&block) }
      # end
      # ----
      # ====
      #
      # @example
      #   # bad
      #   def foo(*args, &block)
      #     bar(*args, &block)
      #   end
      #
      #   # bad
      #   def foo(*args, **kwargs, &block)
      #     bar(*args, **kwargs, &block)
      #   end
      #
      #   # good
      #   def foo(...)
      #     bar(...)
      #   end
      #
      # @example UseAnonymousForwarding: true (default, only relevant for Ruby >= 3.2)
      #   # bad
      #   def foo(*args, **kwargs, &block)
      #     args_only(*args)
      #     kwargs_only(**kwargs)
      #     block_only(&block)
      #   end
      #
      #   # good
      #   def foo(*, **, &)
      #     args_only(*)
      #     kwargs_only(**)
      #     block_only(&)
      #   end
      #
      # @example UseAnonymousForwarding: false (only relevant for Ruby >= 3.2)
      #   # good
      #   def foo(*args, **kwargs, &block)
      #     args_only(*args)
      #     kwargs_only(**kwargs)
      #     block_only(&block)
      #   end
      #
      # @example AllowOnlyRestArgument: true (default, only relevant for Ruby < 3.2)
      #   # good
      #   def foo(*args)
      #     bar(*args)
      #   end
      #
      #   def foo(**kwargs)
      #     bar(**kwargs)
      #   end
      #
      # @example AllowOnlyRestArgument: false (only relevant for Ruby < 3.2)
      #   # bad
      #   # The following code can replace the arguments with `...`,
      #   # but it will change the behavior. Because `...` forwards block also.
      #   def foo(*args)
      #     bar(*args)
      #   end
      #
      #   def foo(**kwargs)
      #     bar(**kwargs)
      #   end
      #
      # @example RedundantRestArgumentNames: ['args', 'arguments'] (default)
      #   # bad
      #   def foo(*args)
      #     bar(*args)
      #   end
      #
      #   # good
      #   def foo(*)
      #     bar(*)
      #   end
      #
      # @example RedundantKeywordRestArgumentNames: ['kwargs', 'options', 'opts'] (default)
      #   # bad
      #   def foo(**kwargs)
      #     bar(**kwargs)
      #   end
      #
      #   # good
      #   def foo(**)
      #     bar(**)
      #   end
      #
      # @example RedundantBlockArgumentNames: ['blk', 'block', 'proc'] (default)
      #   # bad - But it is good with `EnforcedStyle: explicit` set for `Naming/BlockForwarding`.
      #   def foo(&block)
      #     bar(&block)
      #   end
      #
      #   # good
      #   def foo(&)
      #     bar(&)
      #   end
      class ArgumentsForwarding < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.7

        FORWARDING_LVAR_TYPES = %i[splat kwsplat block_pass].freeze
        ADDITIONAL_ARG_TYPES = %i[lvar arg optarg].freeze

        FORWARDING_MSG = 'Use shorthand syntax `...` for arguments forwarding.'
        ARGS_MSG = 'Use anonymous positional arguments forwarding (`*`).'
        KWARGS_MSG = 'Use anonymous keyword arguments forwarding (`**`).'
        BLOCK_MSG = 'Use anonymous block arguments forwarding (`&`).'

        def self.autocorrect_incompatible_with
          [Naming::BlockForwarding]
        end

        def on_def(node)
          return unless node.body

          restarg, kwrestarg, blockarg = extract_forwardable_args(node.arguments)
          forwardable_args = redundant_forwardable_named_args(restarg, kwrestarg, blockarg)
          send_nodes = node.each_descendant(:call, :super, :yield).to_a

          send_classifications = classify_send_nodes(
            node, send_nodes, non_splat_or_block_pass_lvar_references(node.body), forwardable_args
          )

          return if send_classifications.empty?

          if only_forwards_all?(send_classifications)
            add_forward_all_offenses(node, send_classifications, forwardable_args)
          elsif target_ruby_version >= 3.2
            add_post_ruby_32_offenses(node, send_classifications, forwardable_args)
          end
        end

        alias on_defs on_def

        private

        def extract_forwardable_args(args)
          [args.find(&:restarg_type?), args.find(&:kwrestarg_type?), args.find(&:blockarg_type?)]
        end

        def redundant_forwardable_named_args(restarg, kwrestarg, blockarg)
          restarg_node = redundant_named_arg(restarg, 'RedundantRestArgumentNames', '*')
          kwrestarg_node = redundant_named_arg(kwrestarg, 'RedundantKeywordRestArgumentNames', '**')
          blockarg_node = redundant_named_arg(blockarg, 'RedundantBlockArgumentNames', '&')

          [restarg_node, kwrestarg_node, blockarg_node]
        end

        def only_forwards_all?(send_classifications)
          all_classifications = %i[all all_anonymous].freeze
          send_classifications.all? { |_, c, _, _| all_classifications.include?(c) }
        end

        # rubocop:disable Metrics/MethodLength
        def add_forward_all_offenses(node, send_classifications, forwardable_args)
          _rest_arg, _kwrest_arg, block_arg = *forwardable_args
          registered_block_arg_offense = false

          send_classifications.each do |send_node, c, forward_rest, forward_kwrest, forward_block_arg| # rubocop:disable Layout/LineLength
            if !forward_rest && !forward_kwrest && c != :all_anonymous
              if allow_anonymous_forwarding_in_block?(forward_block_arg)
                register_forward_block_arg_offense(!forward_rest, node.arguments, block_arg)
                register_forward_block_arg_offense(!forward_rest, send_node, forward_block_arg)
              end
              registered_block_arg_offense = true
              break
            else
              register_forward_all_offense(send_node, send_node, forward_rest)
            end
          end

          return if registered_block_arg_offense

          rest_arg, _kwrest_arg, _block_arg = *forwardable_args
          register_forward_all_offense(node, node.arguments, rest_arg)
        end
        # rubocop:enable Metrics/MethodLength

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        def add_post_ruby_32_offenses(def_node, send_classifications, forwardable_args)
          return unless use_anonymous_forwarding?
          return unless all_forwarding_offenses_correctable?(send_classifications)

          rest_arg, kwrest_arg, block_arg = *forwardable_args

          send_classifications.each do |send_node, _c, forward_rest, forward_kwrest, forward_block_arg| # rubocop:disable Layout/LineLength
            if allow_anonymous_forwarding_in_block?(forward_rest)
              register_forward_args_offense(def_node.arguments, rest_arg)
              register_forward_args_offense(send_node, forward_rest)
            end

            if allow_anonymous_forwarding_in_block?(forward_kwrest)
              register_forward_kwargs_offense(!forward_rest, def_node.arguments, kwrest_arg)
              register_forward_kwargs_offense(!forward_rest, send_node, forward_kwrest)
            end

            if allow_anonymous_forwarding_in_block?(forward_block_arg)
              register_forward_block_arg_offense(!forward_rest, def_node.arguments, block_arg)
              register_forward_block_arg_offense(!forward_rest, send_node, forward_block_arg)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

        def non_splat_or_block_pass_lvar_references(body)
          body.each_descendant(:lvar, :lvasgn).filter_map do |lvar|
            parent = lvar.parent

            next if lvar.lvar_type? && FORWARDING_LVAR_TYPES.include?(parent.type)

            lvar.children.first
          end.uniq
        end

        def classify_send_nodes(def_node, send_nodes, referenced_lvars, forwardable_args)
          send_nodes.filter_map do |send_node|
            classification_and_forwards = classification_and_forwards(
              def_node,
              send_node,
              referenced_lvars,
              forwardable_args
            )

            next unless classification_and_forwards

            [send_node, *classification_and_forwards]
          end
        end

        def classification_and_forwards(def_node, send_node, referenced_lvars, forwardable_args)
          classifier = SendNodeClassifier.new(
            def_node, send_node, referenced_lvars, forwardable_args,
            target_ruby_version: target_ruby_version,
            allow_only_rest_arguments: allow_only_rest_arguments?
          )

          classification = classifier.classification

          return unless classification

          [
            classification,
            classifier.forwarded_rest_arg,
            classifier.forwarded_kwrest_arg,
            classifier.forwarded_block_arg
          ]
        end

        def redundant_named_arg(arg, config_name, keyword)
          return nil unless arg

          redundant_arg_names = cop_config.fetch(config_name, []).map do |redundant_arg_name|
            "#{keyword}#{redundant_arg_name}"
          end << keyword

          redundant_arg_names.include?(arg.source) ? arg : nil
        end

        # Checks if forwarding is uses both in blocks and outside of blocks.
        # On Ruby 3.3.0, anonymous block forwarding in blocks can be is a syntax
        # error, so we only want to register an offense if we can change all occurrences.
        def all_forwarding_offenses_correctable?(send_classifications)
          return true if target_ruby_version >= 3.4

          send_classifications.none? do |send_node, *|
            send_node.each_ancestor(:any_block).any?
          end
        end

        # Ruby 3.3.0 had a bug where accessing an anonymous block argument inside of a block
        # was a syntax error in unambiguous cases: https://bugs.ruby-lang.org/issues/20090
        # We disallow this also for earlier Ruby versions so that code is forwards compatible.
        def allow_anonymous_forwarding_in_block?(node)
          return false unless node
          return true if target_ruby_version >= 3.4

          node.each_ancestor(:any_block).none?
        end

        def register_forward_args_offense(def_arguments_or_send, rest_arg_or_splat)
          add_offense(rest_arg_or_splat, message: ARGS_MSG) do |corrector|
            add_parens_if_missing(def_arguments_or_send, corrector)

            corrector.replace(rest_arg_or_splat, '*')
          end
        end

        def register_forward_kwargs_offense(add_parens, def_arguments_or_send, kwrest_arg_or_splat)
          add_offense(kwrest_arg_or_splat, message: KWARGS_MSG) do |corrector|
            add_parens_if_missing(def_arguments_or_send, corrector) if add_parens

            corrector.replace(kwrest_arg_or_splat, '**')
          end
        end

        def register_forward_block_arg_offense(add_parens, def_arguments_or_send, block_arg)
          return if target_ruby_version <= 3.0 ||
                    block_arg.nil? || block_arg.source == '&' || explicit_block_name?

          add_offense(block_arg, message: BLOCK_MSG) do |corrector|
            add_parens_if_missing(def_arguments_or_send, corrector) if add_parens

            corrector.replace(block_arg, '&')
          end
        end

        def register_forward_all_offense(def_or_send, send_or_arguments, rest_or_splat)
          arg_range = arguments_range(def_or_send, rest_or_splat)

          add_offense(arg_range, message: FORWARDING_MSG) do |corrector|
            add_parens_if_missing(send_or_arguments, corrector)

            corrector.replace(arg_range, '...')
          end
        end

        # rubocop:disable Metrics/AbcSize
        def arguments_range(node, first_node)
          arguments = node.arguments.reject do |arg|
            next true if ADDITIONAL_ARG_TYPES.include?(arg.type) || arg.variable? || arg.call_type?

            arg.literal? && arg.each_descendant(:kwsplat).none?
          end

          start_node = first_node || arguments.first
          start_node.source_range.begin.join(arguments.last.source_range.end)
        end
        # rubocop:enable Metrics/AbcSize

        def allow_only_rest_arguments?
          cop_config.fetch('AllowOnlyRestArgument', true)
        end

        def use_anonymous_forwarding?
          cop_config.fetch('UseAnonymousForwarding', false)
        end

        def add_parens_if_missing(node, corrector)
          return if parentheses?(node)
          return if node.send_type? && node.method?(:[])

          add_parentheses(node, corrector)
        end

        # Classifies send nodes for possible rest/kwrest/all (including block) forwarding.
        class SendNodeClassifier
          extend NodePattern::Macros

          # @!method forwarded_rest_arg?(node, rest_name)
          def_node_matcher :forwarded_rest_arg?, '(splat (lvar %1))'

          # @!method extract_forwarded_kwrest_arg(node, kwrest_name)
          def_node_matcher :extract_forwarded_kwrest_arg, '(hash <$(kwsplat (lvar %1)) ...>)'

          # @!method forwarded_block_arg?(node, block_name)
          def_node_matcher :forwarded_block_arg?, '(block_pass {(lvar %1) nil?})'

          # @!method def_all_anonymous_args?(node)
          def_node_matcher :def_all_anonymous_args?, <<~PATTERN
            (
              def _
              (args ... (restarg) (kwrestarg) (blockarg nil?))
              _
            )
          PATTERN

          # @!method send_all_anonymous_args?(node)
          def_node_matcher :send_all_anonymous_args?, <<~PATTERN
            (
              send _ _
              ... (forwarded_restarg) (hash (forwarded_kwrestarg)) (block_pass nil?)
            )
          PATTERN

          def initialize(def_node, send_node, referenced_lvars, forwardable_args, **config)
            @def_node = def_node
            @send_node = send_node
            @referenced_lvars = referenced_lvars
            @rest_arg, @kwrest_arg, @block_arg = *forwardable_args
            @rest_arg_name, @kwrest_arg_name, @block_arg_name =
              *forwardable_args.map { |a| a&.name }
            @config = config
          end

          def forwarded_rest_arg
            return nil if referenced_rest_arg?

            arguments.find { |arg| forwarded_rest_arg?(arg, @rest_arg_name) }
          end

          def forwarded_kwrest_arg
            return nil if referenced_kwrest_arg?

            arguments.filter_map { |arg| extract_forwarded_kwrest_arg(arg, @kwrest_arg_name) }.first
          end

          def forwarded_block_arg
            return nil if referenced_block_arg?

            arguments.find { |arg| forwarded_block_arg?(arg, @block_arg_name) }
          end

          def classification
            return nil unless forwarded_rest_arg || forwarded_kwrest_arg || forwarded_block_arg

            if ruby_32_only_anonymous_forwarding?
              :all_anonymous
            elsif can_forward_all?
              :all
            else
              :rest_or_kwrest
            end
          end

          private

          # rubocop:disable Metrics/CyclomaticComplexity
          def can_forward_all?
            return false if any_arg_referenced?
            return false if ruby_30_or_lower_optarg?
            return false if ruby_32_or_higher_missing_rest_or_kwest?
            return false unless offensive_block_forwarding?
            return false if additional_kwargs_or_forwarded_kwargs?

            no_additional_args? || (target_ruby_version >= 3.0 && no_post_splat_args?)
          end
          # rubocop:enable Metrics/CyclomaticComplexity

          # def foo(a = 41, ...) is a syntax error in 3.0.
          def ruby_30_or_lower_optarg?
            target_ruby_version <= 3.0 && @def_node.arguments.any?(&:optarg_type?)
          end

          def ruby_32_only_anonymous_forwarding?
            # A block argument and an anonymous block argument are never passed together.
            return false if @send_node.each_ancestor(:any_block).any?

            def_all_anonymous_args?(@def_node) && send_all_anonymous_args?(@send_node)
          end

          def ruby_32_or_higher_missing_rest_or_kwest?
            target_ruby_version >= 3.2 && !forwarded_rest_and_kwrest_args
          end

          def offensive_block_forwarding?
            @block_arg ? forwarded_block_arg : allow_offense_for_no_block?
          end

          def forwarded_rest_and_kwrest_args
            forwarded_rest_arg && forwarded_kwrest_arg
          end

          def arguments
            @send_node.arguments
          end

          def referenced_rest_arg?
            @referenced_lvars.include?(@rest_arg_name)
          end

          def referenced_kwrest_arg?
            @referenced_lvars.include?(@kwrest_arg_name)
          end

          def referenced_block_arg?
            @referenced_lvars.include?(@block_arg_name)
          end

          def any_arg_referenced?
            referenced_rest_arg? || referenced_kwrest_arg? || referenced_block_arg?
          end

          def target_ruby_version
            @config.fetch(:target_ruby_version)
          end

          def no_post_splat_args?
            return true unless (splat_index = arguments.index(forwarded_rest_arg))

            arg_after_splat = arguments[splat_index + 1]
            [nil, :hash, :block_pass].include?(arg_after_splat&.type)
          end

          def additional_kwargs_or_forwarded_kwargs?
            additional_kwargs? || forward_additional_kwargs?
          end

          def additional_kwargs?
            @def_node.arguments.any? { |a| a.type?(:kwarg, :kwoptarg) }
          end

          def forward_additional_kwargs?
            return false unless forwarded_kwrest_arg

            !forwarded_kwrest_arg.parent.children.one?
          end

          def allow_offense_for_no_block?
            !@config.fetch(:allow_only_rest_arguments)
          end

          def no_additional_args?
            forwardable_count = [@rest_arg, @kwrest_arg, @block_arg].compact.size

            return false if missing_rest_arg_or_kwrest_arg?

            @def_node.arguments.size == forwardable_count &&
              @send_node.arguments.size == forwardable_count
          end

          def missing_rest_arg_or_kwrest_arg?
            (@rest_arg_name && !forwarded_rest_arg) ||
              (@kwrest_arg_name && !forwarded_kwrest_arg)
          end
        end

        def explicit_block_name?
          config.for_enabled_cop('Naming/BlockForwarding')['EnforcedStyle'] == 'explicit'
        end
      end
    end
  end
end
