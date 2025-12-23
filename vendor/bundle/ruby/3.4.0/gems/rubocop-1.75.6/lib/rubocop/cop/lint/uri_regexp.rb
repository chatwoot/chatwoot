# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Identifies places where `URI.regexp` is obsolete and should not be used.
      #
      # For Ruby 3.3 or lower, use `URI::DEFAULT_PARSER.make_regexp`.
      # For Ruby 3.4 or higher, use `URI::RFC2396_PARSER.make_regexp`.
      #
      # NOTE: If you need to support both Ruby 3.3 and lower as well as Ruby 3.4 and higher,
      # consider manually changing the code as follows:
      #
      # [source,ruby]
      # ----
      # defined?(URI::RFC2396_PARSER) ? URI::RFC2396_PARSER : URI::DEFAULT_PARSER
      # ----
      #
      # @example
      #   # bad
      #   URI.regexp('http://example.com')
      #
      #   # good - Ruby 3.3 or lower
      #   URI::DEFAULT_PARSER.make_regexp('http://example.com')
      #
      #   # good - Ruby 3.4 or higher
      #   URI::RFC2396_PARSER.make_regexp('http://example.com')
      #
      class UriRegexp < Base
        extend AutoCorrector

        MSG = '`%<current>s` is obsolete and should not be used. Instead, use `%<preferred>s`.'
        RESTRICT_ON_SEND = %i[regexp].freeze

        # @!method uri_constant?(node)
        def_node_matcher :uri_constant?, <<~PATTERN
          (const {cbase nil?} :URI)
        PATTERN

        def on_send(node)
          return unless uri_constant?(node.receiver)

          parser = target_ruby_version >= 3.4 ? 'RFC2396_PARSER' : 'DEFAULT_PARSER'
          argument = node.first_argument ? "(#{node.first_argument.source})" : ''

          preferred_method = "#{node.receiver.source}::#{parser}.make_regexp#{argument}"
          message = format(MSG, current: node.source, preferred: preferred_method)

          add_offense(node.loc.selector, message: message) do |corrector|
            corrector.replace(node, preferred_method)
          end
        end
      end
    end
  end
end
