# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces consistent style when using `exists?`.
      #
      # Two styles are supported for this cop. When EnforcedStyle is 'exists'
      # then the cop enforces `exists?(...)` over `where(...).exists?`.
      #
      # When EnforcedStyle is 'where' then the cop enforces
      # `where(...).exists?` over `exists?(...)`.
      #
      # @safety
      #   This cop is unsafe for autocorrection because the behavior may change on the following case:
      #
      #   [source,ruby]
      #   ----
      #   Author.includes(:articles).where(articles: {id: id}).exists?
      #   #=> Perform `eager_load` behavior (`LEFT JOIN` query) and get result.
      #
      #   Author.includes(:articles).exists?(articles: {id: id})
      #   #=> Perform `preload` behavior and `ActiveRecord::StatementInvalid` error occurs.
      #   ----
      #
      # @example EnforcedStyle: exists (default)
      #   # bad
      #   User.where(name: 'john').exists?
      #   User.where(['name = ?', 'john']).exists?
      #   User.where('name = ?', 'john').exists?
      #   user.posts.where(published: true).exists?
      #
      #   # good
      #   User.exists?(name: 'john')
      #   User.where('length(name) > 10').exists?
      #   user.posts.exists?(published: true)
      #
      # @example EnforcedStyle: where
      #   # bad
      #   User.exists?(name: 'john')
      #   User.exists?(['name = ?', 'john'])
      #   user.posts.exists?(published: true)
      #
      #   # good
      #   User.where(name: 'john').exists?
      #   User.where(['name = ?', 'john']).exists?
      #   User.where('name = ?', 'john').exists?
      #   user.posts.where(published: true).exists?
      #   User.where('length(name) > 10').exists?
      class WhereExists < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Prefer `%<good_method>s` over `%<bad_method>s`.'
        RESTRICT_ON_SEND = %i[exists?].freeze

        def_node_matcher :where_exists_call?, <<~PATTERN
          (call (call _ :where $...) :exists?)
        PATTERN

        def_node_matcher :exists_with_args?, <<~PATTERN
          (call _ :exists? $...)
        PATTERN

        def on_send(node)
          find_offenses(node) do |args|
            return unless convertable_args?(args)

            range = correction_range(node)
            good_method = build_good_method(args, dot: node.loc.dot)
            message = format(MSG, good_method: good_method, bad_method: range.source)

            add_offense(range, message: message) do |corrector|
              corrector.replace(range, good_method)
            end
          end
        end
        alias on_csend on_send

        private

        def where_style?
          style == :where
        end

        def exists_style?
          style == :exists
        end

        def find_offenses(node, &block)
          if exists_style?
            where_exists_call?(node, &block)
          elsif where_style?
            exists_with_args?(node, &block)
          end
        end

        def convertable_args?(args)
          return false if args.empty?

          args.size > 1 || args[0].hash_type? || args[0].array_type?
        end

        def correction_range(node)
          if exists_style?
            node.receiver.loc.selector.join(node.loc.selector)
          elsif where_style?
            node.loc.selector.with(end_pos: node.source_range.end_pos)
          end
        end

        def build_good_method(args, dot:)
          if exists_style?
            build_good_method_exists(args)
          elsif where_style?
            build_good_method_where(args, dot&.source || '.')
          end
        end

        def build_good_method_exists(args)
          if args.size > 1
            "exists?([#{args.map(&:source).join(', ')}])"
          else
            "exists?(#{args[0].source})"
          end
        end

        def build_good_method_where(args, dot_source)
          if args.size > 1
            "where(#{args.map(&:source).join(', ')})#{dot_source}exists?"
          else
            "where(#{args[0].source})#{dot_source}exists?"
          end
        end
      end
    end
  end
end
