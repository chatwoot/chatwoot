# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # In Ruby 2.5, `String#delete_suffix` has been added.
      #
      # This cop identifies places where `gsub(/suffix\z/, '')` and `sub(/suffix\z/, '')`
      # can be replaced by `delete_suffix('suffix')`.
      #
      # This cop has `SafeMultiline` configuration option that `true` by default because
      # `suffix$` is unsafe as it will behave incompatible with `delete_suffix?`
      # for receiver is multiline string.
      #
      # The `delete_suffix('suffix')` method is faster than `gsub(/suffix\z/, '')`.
      #
      # @safety
      #   This cop is unsafe because `Pathname` has `sub` but not `delete_suffix`.
      #
      # @example
      #
      #   # bad
      #   str.gsub(/suffix\z/, '')
      #   str.gsub!(/suffix\z/, '')
      #
      #   str.sub(/suffix\z/, '')
      #   str.sub!(/suffix\z/, '')
      #
      #   # good
      #   str.delete_suffix('suffix')
      #   str.delete_suffix!('suffix')
      #
      # @example SafeMultiline: true (default)
      #
      #   # good
      #   str.gsub(/suffix$/, '')
      #   str.gsub!(/suffix$/, '')
      #   str.sub(/suffix$/, '')
      #   str.sub!(/suffix$/, '')
      #
      # @example SafeMultiline: false
      #
      #   # bad
      #   str.gsub(/suffix$/, '')
      #   str.gsub!(/suffix$/, '')
      #   str.sub(/suffix$/, '')
      #   str.sub!(/suffix$/, '')
      #
      class DeleteSuffix < Base
        include RegexpMetacharacter
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.5

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'
        RESTRICT_ON_SEND = %i[gsub gsub! sub sub!].freeze

        PREFERRED_METHODS = {
          gsub: :delete_suffix,
          gsub!: :delete_suffix!,
          sub: :delete_suffix,
          sub!: :delete_suffix!
        }.freeze

        def_node_matcher :delete_suffix_candidate?, <<~PATTERN
          (call $!nil? ${:gsub :gsub! :sub :sub!} (regexp (str $#literal_at_end?) (regopt)) (str $_))
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          return unless (receiver, bad_method, regexp_str, replace_string = delete_suffix_candidate?(node))
          return unless replace_string.empty?

          good_method = PREFERRED_METHODS[bad_method]

          message = format(MSG, current: bad_method, prefer: good_method)

          add_offense(node.loc.selector, message: message) do |corrector|
            regexp_str = drop_end_metacharacter(regexp_str)
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
