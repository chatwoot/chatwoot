# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Identifies places where `URI.escape` can be replaced by
      # `CGI.escape`, `URI.encode_www_form`, or `URI.encode_www_form_component`
      # depending on your specific use case.
      # Also this cop identifies places where `URI.unescape` can be replaced by
      # `CGI.unescape`, `URI.decode_www_form`,
      # or `URI.decode_www_form_component` depending on your specific use case.
      #
      # @example
      #   # bad
      #   URI.escape('http://example.com')
      #   URI.encode('http://example.com')
      #
      #   # good
      #   CGI.escape('http://example.com')
      #   URI.encode_www_form([['example', 'param'], ['lang', 'en']])
      #   URI.encode_www_form(page: 10, locale: 'en')
      #   URI.encode_www_form_component('http://example.com')
      #
      #   # bad
      #   URI.unescape(enc_uri)
      #   URI.decode(enc_uri)
      #
      #   # good
      #   CGI.unescape(enc_uri)
      #   URI.decode_www_form(enc_uri)
      #   URI.decode_www_form_component(enc_uri)
      class UriEscapeUnescape < Base
        ALTERNATE_METHODS_OF_URI_ESCAPE = %w[
          CGI.escape
          URI.encode_www_form
          URI.encode_www_form_component
        ].freeze
        ALTERNATE_METHODS_OF_URI_UNESCAPE = %w[
          CGI.unescape
          URI.decode_www_form
          URI.decode_www_form_component
        ].freeze

        MSG = '`%<uri_method>s` method is obsolete and should not be used. ' \
              'Instead, use %<replacements>s depending on your specific use ' \
              'case.'
        METHOD_NAMES = %i[escape encode unescape decode].freeze
        RESTRICT_ON_SEND = METHOD_NAMES

        # @!method uri_escape_unescape?(node)
        def_node_matcher :uri_escape_unescape?, <<~PATTERN
          (send
            (const ${nil? cbase} :URI) ${:#{METHOD_NAMES.join(' :')}}
            ...)
        PATTERN

        def on_send(node)
          uri_escape_unescape?(node) do |top_level, obsolete_method|
            replacements = if %i[escape encode].include?(obsolete_method)
                             ALTERNATE_METHODS_OF_URI_ESCAPE
                           else
                             ALTERNATE_METHODS_OF_URI_UNESCAPE
                           end

            double_colon = top_level ? '::' : ''

            message = format(
              MSG, uri_method: "#{double_colon}URI.#{obsolete_method}",
                   replacements: "`#{replacements[0]}`, `#{replacements[1]}` " \
                                 "or `#{replacements[2]}`"
            )

            add_offense(node, message: message)
          end
        end
      end
    end
  end
end
