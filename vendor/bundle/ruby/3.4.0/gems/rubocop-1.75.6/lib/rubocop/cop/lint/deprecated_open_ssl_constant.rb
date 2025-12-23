# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Algorithmic constants for `OpenSSL::Cipher` and `OpenSSL::Digest`
      # deprecated since OpenSSL version 2.2.0. Prefer passing a string
      # instead.
      #
      # @example
      #
      #   # bad
      #   OpenSSL::Cipher::AES.new(128, :GCM)
      #
      #   # good
      #   OpenSSL::Cipher.new('aes-128-gcm')
      #
      #   # bad
      #   OpenSSL::Digest::SHA256.new
      #
      #   # good
      #   OpenSSL::Digest.new('SHA256')
      #
      #   # bad
      #   OpenSSL::Digest::SHA256.digest('foo')
      #
      #   # good
      #   OpenSSL::Digest.digest('SHA256', 'foo')
      #
      class DeprecatedOpenSSLConstant < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<constant>s.%<method>s(%<replacement_args>s)` instead of `%<original>s`.'

        RESTRICT_ON_SEND = %i[new digest].freeze
        NO_ARG_ALGORITHM = %w[BF DES IDEA RC4].freeze

        # @!method algorithm_const(node)
        def_node_matcher :algorithm_const, <<~PATTERN
          (send
            $(const
              (const
                (const {nil? cbase} :OpenSSL) {:Cipher :Digest})
              _)
            ...)
        PATTERN

        # @!method digest_const?(node)
        def_node_matcher :digest_const?, <<~PATTERN
          (const _ :Digest)
        PATTERN

        def on_send(node)
          return if node.arguments.any? { |arg| arg.variable? || arg.call_type? || arg.const_type? }
          return if digest_const?(node.receiver)
          return unless algorithm_const(node)

          message = message(node)

          add_offense(node, message: message) { |corrector| autocorrect(corrector, node) }
        end

        private

        def autocorrect(corrector, node)
          algorithm_constant, = algorithm_const(node)

          corrector.remove(algorithm_constant.loc.double_colon)
          corrector.remove(algorithm_constant.loc.name)

          corrector.replace(
            correction_range(node),
            "#{node.loc.selector.source}(#{replacement_args(node)})"
          )
        end

        def message(node)
          algorithm_constant, = algorithm_const(node)
          parent_constant = openssl_class(algorithm_constant)
          replacement_args = replacement_args(node)
          method = node.loc.selector.source

          format(
            MSG,
            constant: parent_constant,
            method: method,
            replacement_args: replacement_args,
            original: node.source
          )
        end

        def correction_range(node)
          range_between(node.loc.dot.end_pos, node.source_range.end_pos)
        end

        def openssl_class(node)
          node.children.first.source
        end

        def algorithm_name(node)
          name = node.loc.name.source

          if openssl_class(node) == 'OpenSSL::Cipher' && !NO_ARG_ALGORITHM.include?(name)
            name.scan(/.{3}/).join('-')
          else
            name
          end
        end

        def sanitize_arguments(arguments)
          arguments.flat_map do |arg|
            argument = arg.str_type? ? arg.value : arg.source

            argument.tr(":'", '').split('-')
          end
        end

        def replacement_args(node)
          algorithm_constant, = algorithm_const(node)
          algorithm_name = algorithm_name(algorithm_constant)

          if openssl_class(algorithm_constant) == 'OpenSSL::Cipher'
            build_cipher_arguments(node, algorithm_name, node.arguments.empty?)
          else
            (["'#{algorithm_name}'"] + node.arguments.map(&:source)).join(', ')
          end
        end

        def build_cipher_arguments(node, algorithm_name, no_arguments)
          algorithm_parts = algorithm_name.downcase.split('-')
          size_and_mode = sanitize_arguments(node.arguments).map(&:downcase)

          if NO_ARG_ALGORITHM.include?(algorithm_parts.first.upcase) && no_arguments
            "'#{algorithm_parts.first}'"
          else
            mode = 'cbc' if size_and_mode.empty?

            "'#{(algorithm_parts + size_and_mode + [mode]).compact.take(3).join('-')}'"
          end
        end
      end
    end
  end
end
