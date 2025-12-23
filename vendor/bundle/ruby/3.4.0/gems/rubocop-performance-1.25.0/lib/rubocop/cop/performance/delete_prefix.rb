# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # In Ruby 2.5, `String#delete_prefix` has been added.
      #
      # This cop identifies places where `gsub(/\Aprefix/, '')` and `sub(/\Aprefix/, '')`
      # can be replaced by `delete_prefix('prefix')`.
      #
      # This cop has `SafeMultiline` configuration option that `true` by default because
      # `^prefix` is unsafe as it will behave incompatible with `delete_prefix`
      # for receiver is multiline string.
      #
      # The `delete_prefix('prefix')` method is faster than `gsub(/\Aprefix/, '')`.
      #
      # @safety
      #   This cop is unsafe because `Pathname` has `sub` but not `delete_prefix`.
      #
      # @example
      #
      #   # bad
      #   str.gsub(/\Aprefix/, '')
      #   str.gsub!(/\Aprefix/, '')
      #
      #   str.sub(/\Aprefix/, '')
      #   str.sub!(/\Aprefix/, '')
      #
      #   # good
      #   str.delete_prefix('prefix')
      #   str.delete_prefix!('prefix')
      #
      # @example SafeMultiline: true (default)
      #
      #   # good
      #   str.gsub(/^prefix/, '')
      #   str.gsub!(/^prefix/, '')
      #   str.sub(/^prefix/, '')
      #   str.sub!(/^prefix/, '')
      #
      # @example SafeMultiline: false
      #
      #   # bad
      #   str.gsub(/^prefix/, '')
      #   str.gsub!(/^prefix/, '')
      #   str.sub(/^prefix/, '')
      #   str.sub!(/^prefix/, '')
      #
      class DeletePrefix < Base
        include RegexpMetacharacter
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.5

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'
        RESTRICT_ON_SEND = %i[gsub gsub! sub sub!].freeze

        PREFERRED_METHODS = {
          gsub: :delete_prefix,
          gsub!: :delete_prefix!,
          sub: :delete_prefix,
          sub!: :delete_prefix!
        }.freeze

        def_node_matcher :delete_prefix_candidate?, <<~PATTERN
          (call $!nil? ${:gsub :gsub! :sub :sub!} (regexp (str $#literal_at_start?) (regopt)) (str $_))
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          return unless (receiver, bad_method, regexp_str, replace_string = delete_prefix_candidate?(node))
          return unless replace_string.empty?

          good_method = PREFERRED_METHODS[bad_method]

          message = format(MSG, current: bad_method, prefer: good_method)

          add_offense(node.loc.selector, message: message) do |corrector|
            regexp_str = drop_start_metacharacter(regexp_str)
            regexp_str = interpret_string_escapes(regexp_str)
            string_literal = to_string_literal(regexp_str)

            new_code = "#{receiver.source}#{node.loc.dot.source}#{good_method}(#{string_literal})"

            corrector.replace(node, new_code)
          end
        end
        # rubocop:enable Metrics/AbcSize
        alias on_csend on_send
      end
    end
  end
end
