# frozen_string_literal: true

module RuboCop
  module Cop
    module Bundler
      # Passing symbol arguments to `source` (e.g. `source :rubygems`) is
      # deprecated because they default to using HTTP requests. Instead, specify
      # `'https://rubygems.org'` if possible, or `'http://rubygems.org'` if not.
      #
      # When autocorrecting, this cop will replace symbol arguments with
      # `'https://rubygems.org'`.
      #
      # This cop will not replace existing sources that use `http://`. This may
      # be necessary where HTTPS is not available. For example, where using an
      # internal gem server via an intranet, or where HTTPS is prohibited.
      # However, you should strongly prefer `https://` where possible, as it is
      # more secure.
      #
      # If you don't allow `http://`, please set `false` to `AllowHttpProtocol`.
      # This option is `true` by default for safe autocorrection.
      #
      # @example
      #   # bad
      #   source :gemcutter
      #   source :rubygems
      #   source :rubyforge
      #
      #   # good
      #   source 'https://rubygems.org' # strongly recommended
      #
      # @example AllowHttpProtocol: true (default)
      #
      #   # good
      #   source 'http://rubygems.org' # use only if HTTPS is unavailable
      #
      # @example AllowHttpProtocol: false
      #
      #   # bad
      #   source 'http://rubygems.org'
      #
      class InsecureProtocolSource < Base
        extend AutoCorrector

        MSG = 'The source `:%<source>s` is deprecated because HTTP requests ' \
              'are insecure. ' \
              "Please change your source to 'https://rubygems.org' " \
              "if possible, or 'http://rubygems.org' if not."
        MSG_HTTP_PROTOCOL = 'Use `https://rubygems.org` instead of `http://rubygems.org`.'

        RESTRICT_ON_SEND = %i[source].freeze

        # @!method insecure_protocol_source?(node)
        def_node_matcher :insecure_protocol_source?, <<~PATTERN
          (send nil? :source
            ${(sym :gemcutter) (sym :rubygems) (sym :rubyforge) (:str "http://rubygems.org")})
        PATTERN

        def on_send(node)
          insecure_protocol_source?(node) do |source_node|
            source = source_node.value
            use_http_protocol = source == 'http://rubygems.org'

            return if allow_http_protocol? && use_http_protocol

            message = if use_http_protocol
                        MSG_HTTP_PROTOCOL
                      else
                        format(MSG, source: source)
                      end

            add_offense(source_node, message: message) do |corrector|
              corrector.replace(source_node, "'https://rubygems.org'")
            end
          end
        end

        private

        def allow_http_protocol?
          cop_config.fetch('AllowHttpProtocol', true)
        end
      end
    end
  end
end
