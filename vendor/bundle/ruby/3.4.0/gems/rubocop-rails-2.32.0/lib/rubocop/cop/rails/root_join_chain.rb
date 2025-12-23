# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Use a single `#join` instead of chaining on `Rails.root` or `Rails.public_path`.
      #
      # @example
      #   # bad
      #   Rails.root.join('db').join('schema.rb')
      #   Rails.root.join('db').join(migrate).join('migration.rb')
      #   Rails.public_path.join('path').join('file.pdf')
      #   Rails.public_path.join('path').join(to).join('file.pdf')
      #
      #   # good
      #   Rails.root.join('db', 'schema.rb')
      #   Rails.root.join('db', migrate, 'migration.rb')
      #   Rails.public_path.join('path', 'file.pdf')
      #   Rails.public_path.join('path', to, 'file.pdf')
      #
      class RootJoinChain < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `%<root>s.join(...)` instead of chaining `#join` calls.'

        RESTRICT_ON_SEND = %i[join].to_set.freeze

        # @!method rails_root?(node)
        def_node_matcher :rails_root?, <<~PATTERN
          (send (const {nil? cbase} :Rails) {:root :public_path})
        PATTERN

        # @!method join?(node)
        def_node_matcher :join?, <<~PATTERN
          (send _ :join $...)
        PATTERN

        def on_send(node)
          evidence(node) do |rails_node, args|
            add_offense(node, message: format(MSG, root: rails_node.source)) do |corrector|
              range = range_between(rails_node.loc.selector.end_pos, node.source_range.end_pos)
              replacement = ".join(#{args.map(&:source).join(', ')})"

              corrector.replace(range, replacement)
            end
          end
        end

        private

        def evidence(node)
          # Are we at the *end* of the join chain?
          return if join?(node.parent)
          # Is there only one join?
          return if rails_root?(node.receiver)

          all_args = []

          while (args = join?(node))
            all_args = args + all_args
            node = node.receiver
          end

          rails_root?(node) do
            yield(node, all_args)
          end
        end
      end
    end
  end
end
