# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Favor `Rails.public_path` over `Rails.root` with `'public'`
      #
      # @example
      #   # bad
      #   Rails.root.join('public')
      #   Rails.root.join('public/file.pdf')
      #   Rails.root.join('public', 'file.pdf')
      #
      #   # good
      #   Rails.public_path
      #   Rails.public_path.join('file.pdf')
      #   Rails.public_path.join('file.pdf')
      #
      class RootPublicPath < Base
        extend AutoCorrector

        MSG = 'Use `Rails.public_path`.'

        RESTRICT_ON_SEND = %i[join].to_set.freeze

        PATTERN = %r{\Apublic(/|\z)}.freeze

        def_node_matcher :rails_root_public, <<~PATTERN
          (send
            (send
              $(const {nil? cbase} :Rails) :root) :join
            (str $#public_path?) $...)
        PATTERN

        def on_send(node)
          return unless (rails, maybe_public_path, other_args = rails_root_public(node))

          add_offense(node) do |corrector|
            first_args = maybe_public_path.gsub(PATTERN, '')

            args = other_args.map(&:source)
            args.unshift("'#{first_args}'") unless first_args.empty?

            replacement = "#{rails.source}.public_path"
            replacement += ".join(#{args.join(', ')})" unless args.empty?

            corrector.replace(node, replacement)
          end
        end

        private

        def public_path?(string)
          PATTERN.match?(string)
        end
      end
    end
  end
end
