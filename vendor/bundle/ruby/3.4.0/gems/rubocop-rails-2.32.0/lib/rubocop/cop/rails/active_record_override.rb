# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for overriding built-in Active Record methods instead of using
      # callbacks.
      #
      # @example
      #   # bad
      #   class Book < ApplicationRecord
      #     def save
      #       self.title = title.upcase!
      #       super
      #     end
      #   end
      #
      #   # good
      #   class Book < ApplicationRecord
      #     before_save :upcase_title
      #
      #     def upcase_title
      #       self.title = title.upcase!
      #     end
      #   end
      #
      class ActiveRecordOverride < Base
        MSG = 'Use %<prefer>s callbacks instead of overriding the Active Record method `%<bad>s`.'
        BAD_METHODS = %i[create destroy save update].freeze
        ACTIVE_RECORD_CLASSES = %w[ApplicationRecord ActiveModel::Base ActiveRecord::Base].freeze

        def on_def(node)
          return unless BAD_METHODS.include?(node.method_name)

          parent_class_name = find_parent_class_name(node)
          return unless active_model?(parent_class_name)

          return unless node.descendants.any?(&:zsuper_type?)

          add_offense(node, message: message(node.method_name))
        end

        private

        def active_model?(parent_class_name)
          ACTIVE_RECORD_CLASSES.include?(parent_class_name)
        end

        def callback_names(method_name)
          names = %w[before_ around_ after_].map do |prefix|
            "`#{prefix}#{method_name}`"
          end

          names[-1] = "or #{names.last}"

          names.join(', ')
        end

        def message(method_name)
          format(MSG, prefer: callback_names(method_name), bad: method_name)
        end

        def find_parent_class_name(node)
          return nil unless node

          if node.class_type?
            parent_class_name = node.node_parts[1]

            return nil if parent_class_name.nil?

            return parent_class_name.source
          end

          find_parent_class_name(node.parent)
        end
      end
    end
  end
end
