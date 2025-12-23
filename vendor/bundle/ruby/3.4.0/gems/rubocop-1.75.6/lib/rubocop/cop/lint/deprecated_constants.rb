# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for deprecated constants.
      #
      # It has `DeprecatedConstants` config. If there is an alternative method, you can set
      # alternative value as `Alternative`. And you can set the deprecated version as
      # `DeprecatedVersion`. These options can be omitted if they are not needed.
      #
      #   DeprecatedConstants:
      #     'DEPRECATED_CONSTANT':
      #       Alternative: 'alternative_value'
      #       DeprecatedVersion: 'deprecated_version'
      #
      # By default, `NIL`, `TRUE`, `FALSE`, `Net::HTTPServerException, `Random::DEFAULT`,
      # `Struct::Group`, and `Struct::Passwd` are configured.
      #
      # @example
      #
      #   # bad
      #   NIL
      #   TRUE
      #   FALSE
      #   Net::HTTPServerException
      #   Random::DEFAULT # Return value of Ruby 2 is `Random` instance, Ruby 3.0 is `Random` class.
      #   Struct::Group
      #   Struct::Passwd
      #
      #   # good
      #   nil
      #   true
      #   false
      #   Net::HTTPClientException
      #   Random.new # `::DEFAULT` has been deprecated in Ruby 3, `.new` is compatible with Ruby 2.
      #   Etc::Group
      #   Etc::Passwd
      #
      class DeprecatedConstants < Base
        extend AutoCorrector

        SUGGEST_GOOD_MSG = 'Use `%<good>s` instead of `%<bad>s`%<deprecated_message>s.'
        DO_NOT_USE_MSG = 'Do not use `%<bad>s`%<deprecated_message>s.'

        def on_const(node)
          # FIXME: Workaround for "`undefined method `expression' for nil:NilClass`" when processing
          #        `__ENCODING__`. It is better to be able to work without this condition.
          #        Maybe further investigation of RuboCop AST will lead to an essential solution.
          return unless node.loc

          constant = node.absolute? ? constant_name(node, node.short_name) : node.source
          return unless (deprecated_constant = deprecated_constants[constant])

          alternative = deprecated_constant['Alternative']
          version = deprecated_constant['DeprecatedVersion']
          return if target_ruby_version < version.to_f

          add_offense(node, message: message(alternative, node.source, version)) do |corrector|
            corrector.replace(node, alternative)
          end
        end

        private

        def constant_name(node, nested_constant_name)
          return nested_constant_name.to_s unless node.namespace.const_type?

          constant_name(node.namespace, "#{node.namespace.short_name}::#{nested_constant_name}")
        end

        def message(good, bad, deprecated_version)
          deprecated_message = ", deprecated since Ruby #{deprecated_version}" if deprecated_version

          if good
            format(SUGGEST_GOOD_MSG, good: good, bad: bad, deprecated_message: deprecated_message)
          else
            format(DO_NOT_USE_MSG, bad: bad, deprecated_message: deprecated_message)
          end
        end

        def deprecated_constants
          cop_config.fetch('DeprecatedConstants', {})
        end
      end
    end
  end
end
