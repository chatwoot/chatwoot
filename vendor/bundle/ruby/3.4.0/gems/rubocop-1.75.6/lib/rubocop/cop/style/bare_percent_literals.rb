# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks if usage of %() or %Q() matches configuration.
      #
      # @example EnforcedStyle: bare_percent (default)
      #   # bad
      #   %Q(He said: "#{greeting}")
      #   %q{She said: 'Hi'}
      #
      #   # good
      #   %(He said: "#{greeting}")
      #   %{She said: 'Hi'}
      #
      # @example EnforcedStyle: percent_q
      #   # bad
      #   %|He said: "#{greeting}"|
      #   %/She said: 'Hi'/
      #
      #   # good
      #   %Q|He said: "#{greeting}"|
      #   %q/She said: 'Hi'/
      #
      class BarePercentLiterals < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Use `%%%<good>s` instead of `%%%<bad>s`.'

        def on_dstr(node)
          check(node)
        end

        def on_str(node)
          check(node)
        end

        private

        def check(node)
          return if node.heredoc?
          return unless node.loc.respond_to?(:begin)
          return unless node.loc.begin

          source = node.loc.begin.source
          if requires_percent_q?(source)
            add_offense_for_wrong_style(node, 'Q', '')
          elsif requires_bare_percent?(source)
            add_offense_for_wrong_style(node, '', 'Q')
          end
        end

        def requires_percent_q?(source)
          style == :percent_q && /^%[^\w]/.match?(source)
        end

        def requires_bare_percent?(source)
          style == :bare_percent && source.start_with?('%Q')
        end

        def add_offense_for_wrong_style(node, good, bad)
          location = node.loc.begin

          add_offense(location, message: format(MSG, good: good, bad: bad)) do |corrector|
            source = location.source
            replacement = source.start_with?('%Q') ? '%' : '%Q'

            corrector.replace(location, source.sub(/%Q?/, replacement))
          end
        end
      end
    end
  end
end
