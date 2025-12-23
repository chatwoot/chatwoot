# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks that environments called with `Rails.env` predicates
      # exist.
      # By default the cop allows three environments which Rails ships with:
      # `development`, `test`, and `production`.
      # More can be added to the `Environments` config parameter.
      #
      # @example
      #   # bad
      #   Rails.env.proudction?
      #   Rails.env == 'proudction'
      #
      #   # good
      #   Rails.env.production?
      #   Rails.env == 'production'
      class UnknownEnv < Base
        MSG = 'Unknown environment `%<name>s`.'
        MSG_SIMILAR = 'Unknown environment `%<name>s`. Did you mean `%<similar>s`?'

        def_node_matcher :rails_env?, <<~PATTERN
          (send
            {(const nil? :Rails) (const (cbase) :Rails)}
            :env)
        PATTERN

        def_node_matcher :unknown_environment_predicate?, <<~PATTERN
          (send #rails_env? $#unknown_env_predicate?)
        PATTERN

        def_node_matcher :unknown_environment_equal?, <<~PATTERN
          {
            (send #rails_env? {:== :===} $(str #unknown_env_name?))
            (send $(str #unknown_env_name?) {:== :===} #rails_env?)
          }
        PATTERN

        def on_send(node)
          unknown_environment_predicate?(node) do |name|
            add_offense(node.loc.selector, message: message(name))
          end

          unknown_environment_equal?(node) do |str_node|
            name = str_node.value
            add_offense(str_node, message: message(name))
          end
        end

        private

        def collect_variable_like_names(_scope)
          environments
        end

        def message(name)
          name = name.to_s.chomp('?')

          # DidYouMean::SpellChecker is not available in all versions of Ruby,
          # and even on versions where it *is* available (>= 2.3), it is not
          # always required correctly. So we do a feature check first. See:
          # https://github.com/rubocop/rubocop/issues/7979
          similar_names = if defined?(DidYouMean::SpellChecker)
                            spell_checker = DidYouMean::SpellChecker.new(dictionary: environments)
                            spell_checker.correct(name)
                          else
                            []
                          end

          if similar_names.empty?
            format(MSG, name: name)
          else
            format(MSG_SIMILAR, name: name, similar: similar_names.join(', '))
          end
        end

        def unknown_env_predicate?(name)
          name = name.to_s
          name.end_with?('?') && !environments.include?(name[0..-2])
        end

        def unknown_env_name?(name)
          !environments.include?(name)
        end

        def environments
          @environments ||= begin
            environments = cop_config['Environments'].dup || []
            environments << 'local' if target_rails_version >= 7.1
            environments
          end
        end
      end
    end
  end
end
