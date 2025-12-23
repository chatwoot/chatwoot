# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for the use of methods which skip
      # validations which are listed in
      # https://guides.rubyonrails.org/active_record_validations.html#skipping-validations
      #
      # Methods may be ignored from this rule by configuring a `AllowedMethods`.
      #
      # @safety
      #   This cop is unsafe if the receiver object is not an Active Record object.
      #
      # @example
      #   # bad
      #   Article.first.decrement!(:view_count)
      #   DiscussionBoard.decrement_counter(:post_count, 5)
      #   Article.first.increment!(:view_count)
      #   DiscussionBoard.increment_counter(:post_count, 5)
      #   person.toggle :active
      #   product.touch
      #   Billing.update_all("category = 'authorized', author = 'David'")
      #   user.update_attribute(:website, 'example.com')
      #   user.update_columns(last_request_at: Time.current)
      #   Post.update_counters 5, comment_count: -1, action_count: 1
      #
      #   # good
      #   user.update(website: 'example.com')
      #   FileUtils.touch('file')
      #
      # @example AllowedMethods: ["touch"]
      #   # bad
      #   DiscussionBoard.decrement_counter(:post_count, 5)
      #   DiscussionBoard.increment_counter(:post_count, 5)
      #   person.toggle :active
      #
      #   # good
      #   user.touch
      #
      class SkipsModelValidations < Base
        MSG = 'Avoid using `%<method>s` because it skips validations.'

        METHODS_WITH_ARGUMENTS = %w[decrement!
                                    decrement_counter
                                    increment!
                                    increment_counter
                                    insert
                                    insert!
                                    insert_all
                                    insert_all!
                                    toggle!
                                    update_all
                                    update_attribute
                                    update_column
                                    update_columns
                                    update_counters
                                    upsert
                                    upsert_all].freeze

        def_node_matcher :good_touch?, <<~PATTERN
          {
            (send (const {nil? cbase} :FileUtils) :touch ...)
            (send _ :touch boolean)
          }
        PATTERN

        def_node_matcher :good_insert?, <<~PATTERN
          (call _ {:insert :insert!} _ {
            !(hash ...)
            (hash <(pair (sym !{:returning :unique_by}) _) ...>)
          } ...)
        PATTERN

        def on_send(node)
          return if allowed_methods.include?(node.method_name.to_s)
          return unless forbidden_methods.include?(node.method_name.to_s)
          return if allowed_method?(node)
          return if good_touch?(node)
          return if good_insert?(node)

          add_offense(node.loc.selector, message: message(node))
        end
        alias on_csend on_send

        def initialize(*)
          super
          @displayed_allowed_warning = false
          @displayed_forbidden_warning = false
        end

        private

        def message(node)
          format(MSG, method: node.method_name)
        end

        def allowed_method?(node)
          METHODS_WITH_ARGUMENTS.include?(node.method_name.to_s) && !node.arguments?
        end

        def forbidden_methods
          # TODO: Remove when RuboCop Rails 3 releases.
          obsolete_result = cop_config['Blacklist'] # rubocop:disable InternalAffairs/UndefinedConfig
          if obsolete_result
            warn '`Blacklist` has been renamed to `ForbiddenMethods`.' unless @displayed_forbidden_warning
            @displayed_forbidden_warning = true
            return obsolete_result
          end

          cop_config['ForbiddenMethods'] || []
        end

        def allowed_methods
          # TODO: Remove when RuboCop Rails 3 releases.
          obsolete_result = cop_config['Whitelist'] # rubocop:disable InternalAffairs/UndefinedConfig
          if obsolete_result
            warn '`Whitelist` has been renamed to `AllowedMethods`.' unless @displayed_allowed_warning
            @displayed_allowed_warning = true

            return obsolete_result
          end

          cop_config['AllowedMethods'] || []
        end
      end
    end
  end
end
