# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for uses of the deprecated class method usages.
      #
      # @example
      #
      #   # bad
      #   File.exists?(some_path)
      #   Dir.exists?(some_path)
      #   iterator?
      #   attr :name, true
      #   attr :name, false
      #   ENV.freeze # Calling `Env.freeze` raises `TypeError` since Ruby 2.7.
      #   ENV.clone
      #   ENV.dup # Calling `Env.dup` raises `TypeError` since Ruby 3.1.
      #   Socket.gethostbyname(host)
      #   Socket.gethostbyaddr(host)
      #
      #   # good
      #   File.exist?(some_path)
      #   Dir.exist?(some_path)
      #   block_given?
      #   attr_accessor :name
      #   attr_reader :name
      #   ENV # `ENV.freeze` cannot prohibit changes to environment variables.
      #   ENV.to_h
      #   ENV.to_h # `ENV.dup` cannot dup `ENV`, use `ENV.to_h` to get a copy of `ENV` as a hash.
      #   Addrinfo.getaddrinfo(nodename, service)
      #   Addrinfo.tcp(host, port).getnameinfo
      class DeprecatedClassMethods < Base
        extend AutoCorrector

        MSG = '`%<current>s` is deprecated in favor of `%<prefer>s`.'
        RESTRICT_ON_SEND = %i[
          attr clone dup exists? freeze gethostbyaddr gethostbyname iterator?
        ].freeze

        PREFERRED_METHODS = {
          clone: 'to_h',
          dup: 'to_h',
          exists?: 'exist?',
          gethostbyaddr: 'Addrinfo#getnameinfo',
          gethostbyname: 'Addrinfo.getaddrinfo',
          iterator?: 'block_given?'
        }.freeze

        DIR_ENV_FILE_CONSTANTS = %i[Dir ENV File].freeze

        # @!method deprecated_class_method?(node)
        def_node_matcher :deprecated_class_method?, <<~PATTERN
          {
            (send (const {cbase nil?} :ENV) {:clone :dup :freeze})
            (send (const {cbase nil?} {:File :Dir}) :exists? _)
            (send (const {cbase nil?} :Socket) {:gethostbyaddr :gethostbyname} ...)
            (send nil? :attr _ boolean)
            (send nil? :iterator?)
          }
        PATTERN

        def on_send(node)
          return unless deprecated_class_method?(node)

          offense_range = offense_range(node)
          prefer = preferred_method(node)
          message = format(MSG, current: offense_range.source, prefer: prefer)

          add_offense(offense_range, message: message) do |corrector|
            next if socket_const?(node.receiver)

            if node.method?(:freeze)
              corrector.replace(node, 'ENV')
            else
              corrector.replace(offense_range, prefer)
            end
          end
        end

        private

        def offense_range(node)
          if socket_const?(node.receiver) || dir_env_file_const?(node.receiver)
            node.source_range.begin.join(node.loc.selector.end)
          elsif node.method?(:attr)
            node
          else
            node.loc.selector
          end
        end

        def preferred_method(node)
          if node.method?(:attr)
            boolean_argument = node.arguments[1].source
            preferred_attr_method = boolean_argument == 'true' ? 'attr_accessor' : 'attr_reader'

            "#{preferred_attr_method} #{node.first_argument.source}"
          elsif dir_env_file_const?(node.receiver)
            prefer = PREFERRED_METHODS[node.method_name]

            prefer ? "#{node.receiver.source}.#{prefer}" : 'ENV'
          else
            PREFERRED_METHODS[node.method_name]
          end
        end

        def socket_const?(node)
          node&.short_name == :Socket
        end

        def dir_env_file_const?(node)
          DIR_ENV_FILE_CONSTANTS.include?(node&.short_name)
        end
      end
    end
  end
end
