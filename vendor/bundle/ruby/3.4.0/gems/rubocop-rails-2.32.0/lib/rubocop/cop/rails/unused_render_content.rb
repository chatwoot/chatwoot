# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # If you try to render content along with a non-content status code (100-199, 204, 205, or 304),
      # it will be dropped from the response.
      #
      # This cop checks for uses of `render` which specify both body content and a non-content status.
      #
      # @example
      #   # bad
      #   render 'foo', status: :continue
      #   render status: 100, plain: 'Ruby!'
      #
      #   # good
      #   head :continue
      #   head 100
      class UnusedRenderContent < Base
        include RangeHelp

        MSG = 'Do not specify body content for a response with a non-content status code'
        RESTRICT_ON_SEND = %i[render].freeze
        NON_CONTENT_STATUS_CODES = Set[*100..199, 204, 205, 304] & ::Rack::Utils::SYMBOL_TO_STATUS_CODE.values
        NON_CONTENT_STATUSES = Set[
          *::Rack::Utils::SYMBOL_TO_STATUS_CODE.invert.fetch_values(*NON_CONTENT_STATUS_CODES)
        ]
        BODY_OPTIONS = Set[
          :action,
          :body,
          :content_type,
          :file,
          :html,
          :inline,
          :json,
          :js,
          :layout,
          :plain,
          :raw,
          :template,
          :text,
          :xml
        ]

        def_node_matcher :non_content_status?, <<~PATTERN
          (pair
            (sym :status)
            {(sym NON_CONTENT_STATUSES) (int NON_CONTENT_STATUS_CODES)}
          )
        PATTERN

        def_node_matcher :unused_render_content?, <<~PATTERN
          (send nil? :render {
            (hash <#non_content_status? $(pair (sym BODY_OPTIONS) _) ...>) |
            $({str sym} _) (hash <#non_content_status? ...>)
          })
        PATTERN

        def on_send(node)
          unused_render_content?(node) do |unused_content_node|
            add_offense(unused_content_node)
          end
        end
      end
    end
  end
end
