# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies usages of http methods like `get`, `post`,
      # `put`, `patch` without the usage of keyword arguments in your tests and
      # change them to use keyword args. This cop only applies to Rails >= 5.
      # If you are running Rails < 5 you should disable the
      # Rails/HttpPositionalArguments cop or set your TargetRailsVersion in your
      # .rubocop.yml file to 4.2.
      #
      # NOTE: It does not detect any cases where `include Rack::Test::Methods` is used
      # which makes the http methods incompatible behavior.
      #
      # @example
      #   # bad
      #   get :new, { user_id: 1}
      #
      #   # good
      #   get :new, params: { user_id: 1 }
      #   get :new, **options
      class HttpPositionalArguments < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRailsVersion

        MSG = 'Use keyword arguments instead of positional arguments for http call: `%<verb>s`.'
        KEYWORD_ARGS = %i[method params session body flash xhr as headers env to].freeze
        ROUTING_METHODS = %i[draw routes].freeze
        RESTRICT_ON_SEND = %i[get post put patch delete head].freeze

        minimum_target_rails_version 5.0

        def_node_matcher :http_request?, <<~PATTERN
          (send nil? {#{RESTRICT_ON_SEND.map(&:inspect).join(' ')}} !nil? $_ ...)
        PATTERN

        def_node_matcher :kwsplat_hash?, <<~PATTERN
          (hash (kwsplat _))
        PATTERN

        def_node_matcher :forwarded_kwrestarg?, <<~PATTERN
          (hash (forwarded-kwrestarg))
        PATTERN

        def_node_matcher :include_rack_test_methods?, <<~PATTERN
          (send nil? :include
            (const
              (const
                (const {nil? cbase} :Rack) :Test) :Methods))
        PATTERN

        def on_send(node)
          return if in_routing_block?(node) || use_rack_test_methods?

          http_request?(node) do |data|
            return unless needs_conversion?(data)

            message = format(MSG, verb: node.method_name)

            add_offense(highlight_range(node), message: message) do |corrector|
              # given a pre Rails 5 method: get :new, {user_id: @user.id}, {}
              #
              # @return lambda of auto correct procedure
              # the result should look like:
              #     get :new, params: { user_id: @user.id }, session: {}
              # the http_method is the method used to call the controller
              # the controller node can be a symbol, method, object or string
              # that represents the path/action on the Rails controller
              # the data is the http parameters and environment sent in
              # the Rails 5 http call
              corrector.replace(node, correction(node))
            end
          end
        end

        private

        def in_routing_block?(node)
          !!node.each_ancestor(:block).detect { |block| ROUTING_METHODS.include?(block.method_name) }
        end

        def use_rack_test_methods?
          processed_source.ast.each_descendant(:send).any? do |node|
            include_rack_test_methods?(node)
          end
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def needs_conversion?(data)
          return false if data.forwarded_args_type? || forwarded_kwrestarg?(data)
          return true unless data.hash_type?
          return false if kwsplat_hash?(data)

          data.each_pair.none? do |pair|
            special_keyword_arg?(pair.key) || (format_arg?(pair.key) && data.pairs.one?)
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def special_keyword_arg?(node)
          node.sym_type? && KEYWORD_ARGS.include?(node.value)
        end

        def format_arg?(node)
          node.sym_type? && node.value == :format
        end

        def highlight_range(node)
          _http_path, *data = *node.arguments

          range_between(data.first.source_range.begin_pos, data.last.source_range.end_pos)
        end

        def convert_hash_data(data, type)
          return '' if data.hash_type? && data.empty?

          hash_data = if data.hash_type?
                        format('{ %<data>s }', data: data.pairs.map(&:source).join(', '))
                      else
                        # user supplies an object,
                        # no need to surround with braces
                        data.source
                      end

          format(', %<type>s: %<hash_data>s', type: type, hash_data: hash_data)
        end

        def correction(node)
          http_path, *data = *node.arguments

          controller_action = http_path.source
          params = convert_hash_data(data.first, 'params')
          session = convert_hash_data(data.last, 'session') if data.size > 1

          format(correction_template(node), name: node.method_name,
                                            action: controller_action,
                                            params: params,
                                            session: session)
        end

        def correction_template(node)
          if parentheses?(node)
            '%<name>s(%<action>s%<params>s%<session>s)'
          else
            '%<name>s %<action>s%<params>s%<session>s'
          end
        end
      end
    end
  end
end
