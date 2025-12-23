# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces use of symbolic or numeric value to define HTTP status.
      #
      # @example EnforcedStyle: symbolic (default)
      #   # bad
      #   render :foo, status: 200
      #   render :foo, status: '200'
      #   render json: { foo: 'bar' }, status: 200
      #   render plain: 'foo/bar', status: 304
      #   redirect_to root_url, status: 301
      #   head 200
      #   assert_response 200
      #   assert_redirected_to '/some/path', status: 301
      #
      #   # good
      #   render :foo, status: :ok
      #   render json: { foo: 'bar' }, status: :ok
      #   render plain: 'foo/bar', status: :not_modified
      #   redirect_to root_url, status: :moved_permanently
      #   head :ok
      #   assert_response :ok
      #   assert_redirected_to '/some/path', status: :moved_permanently
      #
      # @example EnforcedStyle: numeric
      #   # bad
      #   render :foo, status: :ok
      #   render json: { foo: 'bar' }, status: :not_found
      #   render plain: 'foo/bar', status: :not_modified
      #   redirect_to root_url, status: :moved_permanently
      #   head :ok
      #   assert_response :ok
      #   assert_redirected_to '/some/path', status: :moved_permanently
      #
      #   # good
      #   render :foo, status: 200
      #   render json: { foo: 'bar' }, status: 404
      #   render plain: 'foo/bar', status: 304
      #   redirect_to root_url, status: 301
      #   head 200
      #   assert_response 200
      #   assert_redirected_to '/some/path', status: 301
      #
      class HttpStatus < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        RESTRICT_ON_SEND = %i[render redirect_to head assert_response assert_redirected_to].freeze

        def_node_matcher :http_status, <<~PATTERN
          {
            (send nil? {:render :redirect_to} _ $hash)
            (send nil? {:render :redirect_to} $hash)
            (send nil? {:head :assert_response} ${int sym} ...)
            (send nil? :assert_redirected_to _ $hash ...)
            (send nil? :assert_redirected_to $hash ...)
          }
        PATTERN

        def_node_matcher :status_code, <<~PATTERN
          (hash <(pair (sym :status) ${int sym str}) ...>)
        PATTERN

        def on_send(node)
          http_status(node) do |hash_node_or_status_code|
            status = if hash_node_or_status_code.hash_type?
                       status_code(hash_node_or_status_code)
                     else
                       hash_node_or_status_code
                     end
            return unless status

            checker = checker_class.new(status)
            return unless checker.offensive?

            add_offense(checker.node, message: checker.message) do |corrector|
              corrector.replace(checker.node, checker.preferred_style)
            end
          end
        end

        private

        def checker_class
          case style
          when :symbolic
            SymbolicStyleChecker
          when :numeric
            NumericStyleChecker
          end
        end

        # :nodoc:
        class SymbolicStyleChecker
          MSG = 'Prefer `%<prefer>s` over `%<current>s` to define HTTP status code.'
          DEFAULT_MSG = 'Prefer `symbolic` over `numeric` to define HTTP status code.'

          attr_reader :node

          def initialize(node)
            @node = node
          end

          def offensive?
            !node.sym_type? && !custom_http_status_code?
          end

          def message
            format(MSG, prefer: preferred_style, current: number.to_s)
          end

          def preferred_style
            symbol.inspect
          end

          private

          def symbol
            ::Rack::Utils::SYMBOL_TO_STATUS_CODE.key(number.to_i)
          end

          def number
            node.children.first
          end

          def custom_http_status_code?
            node.int_type? && !::Rack::Utils::SYMBOL_TO_STATUS_CODE.value?(number)
          end
        end

        # :nodoc:
        class NumericStyleChecker
          MSG = 'Prefer `%<prefer>s` over `%<current>s` to define HTTP status code.'
          DEFAULT_MSG = 'Prefer `numeric` over `symbolic` to define HTTP status code.'
          PERMITTED_STATUS = %i[error success missing redirect].freeze

          attr_reader :node

          def initialize(node)
            @node = node
          end

          def offensive?
            !node.int_type? && !permitted_symbol? && number
          end

          def message
            format(MSG, prefer: preferred_style, current: symbol.inspect)
          end

          def preferred_style
            number.to_s
          end

          private

          def number
            ::Rack::Utils::SYMBOL_TO_STATUS_CODE[symbol]
          end

          def symbol
            node.value
          end

          def permitted_symbol?
            node.sym_type? && PERMITTED_STATUS.include?(node.value)
          end
        end
      end
    end
  end
end
