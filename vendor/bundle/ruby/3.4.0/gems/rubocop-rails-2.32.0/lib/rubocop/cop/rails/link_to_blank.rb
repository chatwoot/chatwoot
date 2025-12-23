# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for calls to `link_to`, `link_to_if`, and `link_to_unless` methods that contain a
      # `target: '_blank'` but no `rel: 'noopener'`. This can be a security
      # risk as the loaded page will have control over the previous page
      # and could change its location for phishing purposes.
      #
      # The option `rel: 'noreferrer'` also blocks this behavior
      # and removes the http-referrer header.
      #
      # @example
      #   # bad
      #   link_to 'Click here', url, target: '_blank'
      #
      #   # good
      #   link_to 'Click here', url, target: '_blank', rel: 'noopener'
      #
      #   # good
      #   link_to 'Click here', url, target: '_blank', rel: 'noreferrer'
      class LinkToBlank < Base
        extend AutoCorrector

        MSG = 'Specify a `:rel` option containing noopener.'
        RESTRICT_ON_SEND = %i[link_to link_to_if link_to_unless].freeze

        def_node_matcher :blank_target?, <<~PATTERN
          (pair {(sym :target) (str "target")} {(str "_blank") (sym :_blank)})
        PATTERN

        def_node_matcher :includes_noopener?, <<~PATTERN
          (pair {(sym :rel) (str "rel")} ({str sym} #contains_noopener?))
        PATTERN

        def_node_matcher :rel_node?, <<~PATTERN
          (pair {(sym :rel) (str "rel")} (str _))
        PATTERN

        def on_send(node)
          option_nodes = node.each_child_node(:hash)

          option_nodes.map(&:children).each do |options|
            blank = options.find { |o| blank_target?(o) }
            next unless blank && options.none? { |o| includes_noopener?(o) }

            add_offense(blank) do |corrector|
              autocorrect(corrector, node, blank, option_nodes)
            end
          end
        end

        private

        def autocorrect(corrector, send_node, node, option_nodes)
          rel_node = nil
          option_nodes.map(&:children).each do |options|
            rel_node ||= options.find { |o| rel_node?(o) }
          end

          if rel_node
            append_to_rel(rel_node, corrector)
          else
            add_rel(send_node, node, corrector)
          end
        end

        def append_to_rel(rel_node, corrector)
          existing_rel = rel_node.children.last.value
          str_range = rel_node.children.last.source_range.adjust(begin_pos: 1, end_pos: -1)
          corrector.replace(str_range, "#{existing_rel} noopener")
        end

        def add_rel(send_node, offense_node, corrector)
          opening_quote = offense_node.children.last.source[0]
          closing_quote = opening_quote == ':' ? '' : opening_quote
          new_rel_exp = ", rel: #{opening_quote}noopener#{closing_quote}"
          range = if (last_argument = send_node.last_argument).hash_type?
                    last_argument.pairs.last.source_range
                  else
                    last_argument.source_range
                  end

          corrector.insert_after(range, new_rel_exp)
        end

        def contains_noopener?(value)
          return false unless value

          rel_array = value.to_s.split
          rel_array.include?('noopener') || rel_array.include?('noreferrer')
        end
      end
    end
  end
end
