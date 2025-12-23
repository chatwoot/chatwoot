# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks that ActiveSupport aliases to core ruby methods
      # are not used.
      #
      # @example
      #   # good
      #   'some_string'.start_with?('prefix')
      #   'some_string'.end_with?('suffix')
      #   [1, 2, 'a'] << 'b'
      #   [1, 2, 'a'].unshift('b')
      #
      #   # bad
      #   'some_string'.starts_with?('prefix')
      #   'some_string'.ends_with?('suffix')
      #   [1, 2, 'a'].append('b')
      #   [1, 2, 'a'].prepend('b')
      #
      class ActiveSupportAliases < Base
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'
        RESTRICT_ON_SEND = %i[starts_with? ends_with? append prepend].freeze

        ALIASES = {
          starts_with?: {
            original: :start_with?, matcher: '(call str :starts_with? _)'
          },
          ends_with?: {
            original: :end_with?, matcher: '(call str :ends_with? _)'
          },
          append: { original: :<<, matcher: '(call array :append _)' },
          prepend: { original: :unshift, matcher: '(call array :prepend _)' }
        }.freeze

        ALIASES.each do |aliased_method, options|
          def_node_matcher aliased_method, options[:matcher]
        end

        def on_send(node)
          ALIASES.each_key do |aliased_method|
            next unless public_send(aliased_method, node)

            preferred_method = ALIASES[aliased_method][:original]
            message = format(MSG, prefer: preferred_method, current: aliased_method)

            add_offense(node.loc.selector.join(node.source_range.end), message: message) do |corrector|
              next if append(node)

              corrector.replace(node.loc.selector, preferred_method)
            end
          end
        end
        alias on_csend on_send
      end
    end
  end
end
