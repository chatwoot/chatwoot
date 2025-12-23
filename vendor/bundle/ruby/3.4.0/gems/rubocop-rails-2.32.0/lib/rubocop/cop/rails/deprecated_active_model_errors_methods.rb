# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks direct manipulation of ActiveModel#errors as hash.
      # These operations are deprecated in Rails 6.1 and will not work in Rails 7.
      #
      # @safety
      #   This cop is unsafe because it can report `errors` manipulation on non-ActiveModel,
      #   which is obviously valid.
      #   The cop has no way of knowing whether a variable is an ActiveModel or not.
      #
      # @example
      #   # bad
      #   user.errors[:name] << 'msg'
      #   user.errors.messages[:name] << 'msg'
      #
      #   # good
      #   user.errors.add(:name, 'msg')
      #
      #   # bad
      #   user.errors[:name].clear
      #   user.errors.messages[:name].clear
      #
      #   # good
      #   user.errors.delete(:name)
      #
      #   # bad
      #   user.errors.keys.include?(:attr)
      #
      #   # good
      #   user.errors.attribute_names.include?(:attr)
      #
      class DeprecatedActiveModelErrorsMethods < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Avoid manipulating ActiveModel errors as hash directly.'
        AUTOCORRECTABLE_METHODS = %i[<< clear keys].freeze
        INCOMPATIBLE_METHODS = %i[keys values to_h to_xml].freeze

        MANIPULATIVE_METHODS = Set[
          *%i[
            << append clear collect! compact! concat
            delete delete_at delete_if drop drop_while fill filter! keep_if
            flatten! insert map! pop prepend push reject! replace reverse!
            rotate! select! shift shuffle! slice! sort! sort_by! uniq! unshift
          ]
        ].freeze

        def_node_matcher :receiver_matcher_outside_model, '{send ivar lvar}'
        def_node_matcher :receiver_matcher_inside_model, '{nil? send ivar lvar}'

        def_node_matcher :any_manipulation?, <<~PATTERN
          {
            #root_manipulation?
            #root_assignment?
            #errors_deprecated?
            #messages_details_manipulation?
            #messages_details_assignment?
          }
        PATTERN

        def_node_matcher :root_manipulation?, <<~PATTERN
          (send
            (send
              (send #receiver_matcher :errors) :[] ...)
            MANIPULATIVE_METHODS
            ...
          )
        PATTERN

        def_node_matcher :root_assignment?, <<~PATTERN
          (send
            (send #receiver_matcher :errors)
            :[]=
            ...)
        PATTERN

        def_node_matcher :errors_deprecated?, <<~PATTERN
          (send
            (send #receiver_matcher :errors)
            {:keys :values :to_h :to_xml})
        PATTERN

        def_node_matcher :messages_details_manipulation?, <<~PATTERN
          (send
            (send
              (send
                (send #receiver_matcher :errors)
                {:messages :details})
                :[]
                ...)
              MANIPULATIVE_METHODS
            ...)
        PATTERN

        def_node_matcher :messages_details_assignment?, <<~PATTERN
          (send
            (send
              (send #receiver_matcher :errors)
              {:messages :details})
            :[]=
            ...)
        PATTERN

        def on_send(node)
          any_manipulation?(node) do
            next if target_rails_version <= 6.0 && INCOMPATIBLE_METHODS.include?(node.method_name)

            add_offense(node) do |corrector|
              next if skip_autocorrect?(node)

              autocorrect(corrector, node)
            end
          end
        end

        private

        def skip_autocorrect?(node)
          return true unless AUTOCORRECTABLE_METHODS.include?(node.method_name)
          return false unless (receiver = node.receiver.receiver)

          receiver.send_type? && receiver.method?(:details) && node.method?(:<<)
        end

        def autocorrect(corrector, node)
          receiver = node.receiver

          range = offense_range(node, receiver)
          replacement = replacement(node, receiver)

          corrector.replace(range, replacement)
        end

        def offense_range(node, receiver)
          receiver = receiver.receiver while receiver.send_type? && !receiver.method?(:errors) && receiver.receiver
          range_between(receiver.source_range.end_pos, node.source_range.end_pos)
        end

        def replacement(node, receiver)
          return '.attribute_names' if node.method?(:keys)

          key = receiver.first_argument.source

          case node.method_name
          when :<<
            value = node.first_argument.source

            ".add(#{key}, #{value})"
          when :clear
            ".delete(#{key})"
          end
        end

        def receiver_matcher(node)
          model_file? ? receiver_matcher_inside_model(node) : receiver_matcher_outside_model(node)
        end

        def model_file?
          processed_source.file_path.include?('/models/')
        end
      end
    end
  end
end
