# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for inline rendering within controller actions.
      #
      # @example
      #   # bad
      #   class ProductsController < ApplicationController
      #     def index
      #       render inline: "<% products.each do |p| %><p><%= p.name %></p><% end %>", type: :erb
      #     end
      #   end
      #
      #   # good
      #   # app/views/products/index.html.erb
      #   # <% products.each do |p| %>
      #   #   <p><%= p.name %></p>
      #   # <% end %>
      #
      #   class ProductsController < ApplicationController
      #     def index
      #     end
      #   end
      #
      class RenderInline < Base
        MSG = 'Prefer using a template over inline rendering.'
        RESTRICT_ON_SEND = %i[render].freeze

        def_node_matcher :render_with_inline_option?, <<~PATTERN
          (send nil? :render (hash <(pair {(sym :inline) (str "inline")} _) ...>))
        PATTERN

        def on_send(node)
          add_offense(node) if render_with_inline_option?(node)
        end
      end
    end
  end
end
