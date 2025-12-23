# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks dynamic `find_by_*` methods.
      # Use `find_by` instead of dynamic method.
      # See. https://rails.rubystyle.guide#find_by
      #
      # @safety
      #   It is certainly unsafe when not configured properly, i.e. user-defined `find_by_xxx`
      #   method is not added to cop's `AllowedMethods`.
      #
      # @example
      #   # bad
      #   User.find_by_name(name)
      #   User.find_by_name_and_email(name)
      #   User.find_by_email!(name)
      #
      #   # good
      #   User.find_by(name: name)
      #   User.find_by(name: name, email: email)
      #   User.find_by!(email: email)
      #
      # @example AllowedMethods: ['find_by_sql', 'find_by_token_for'] (default)
      #   # bad
      #   User.find_by_query(users_query)
      #   User.find_by_token_for(:password_reset, token)
      #
      #   # good
      #   User.find_by_sql(users_sql)
      #   User.find_by_token_for(:password_reset, token)
      #
      # @example AllowedReceivers: ['Gem::Specification', 'page'] (default)
      #   # bad
      #   Specification.find_by_name('backend').gem_dir
      #   page.find_by_id('a_dom_id').click
      #
      #   # good
      #   Gem::Specification.find_by_name('backend').gem_dir
      #   page.find_by_id('a_dom_id').click
      class DynamicFindBy < Base
        include ActiveRecordHelper
        extend AutoCorrector

        MSG = 'Use `%<static_name>s` instead of dynamic `%<method>s`.'
        METHOD_PATTERN = /^find_by_(.+?)(!)?$/.freeze
        IGNORED_ARGUMENT_TYPES = %i[hash splat].freeze

        def on_send(node)
          return if (node.receiver.nil? && !inherit_active_record_base?(node)) || allowed_invocation?(node)

          method_name = node.method_name
          static_name = static_method_name(method_name)
          return unless static_name
          return unless dynamic_find_by_arguments?(node)

          message = format(MSG, static_name: static_name, method: method_name)
          add_offense(node, message: message) do |corrector|
            autocorrect(corrector, node)
          end
        end
        alias on_csend on_send

        private

        def autocorrect(corrector, node)
          autocorrect_method_name(corrector, node)
          autocorrect_argument_keywords(corrector, node, column_keywords(node.method_name))
        end

        def allowed_invocation?(node)
          allowed_method?(node) || allowed_receiver?(node) || whitelisted?(node)
        end

        def allowed_method?(node)
          return false unless cop_config['AllowedMethods']

          cop_config['AllowedMethods'].include?(node.method_name.to_s)
        end

        def allowed_receiver?(node)
          return false unless cop_config['AllowedReceivers'] && node.receiver

          cop_config['AllowedReceivers'].include?(node.receiver.source)
        end

        # config option `WhiteList` will be deprecated soon
        def whitelisted?(node)
          whitelist_config = cop_config['Whitelist']
          return false unless whitelist_config

          whitelist_config.include?(node.method_name.to_s)
        end

        def autocorrect_method_name(corrector, node)
          corrector.replace(node.loc.selector, static_method_name(node.method_name.to_s))
        end

        def autocorrect_argument_keywords(corrector, node, keywords)
          keywords.each.with_index do |keyword, idx|
            corrector.insert_before(node.arguments[idx], keyword)
          end
        end

        def column_keywords(method)
          keyword_string = method.to_s[METHOD_PATTERN, 1]
          keyword_string.split('_and_').map { |keyword| "#{keyword}: " }
        end

        # Returns static method name.
        # If code isn't wrong, returns nil
        def static_method_name(method_name)
          match = METHOD_PATTERN.match(method_name)
          return nil unless match

          match[2] ? 'find_by!' : 'find_by'
        end

        def dynamic_find_by_arguments?(node)
          dynamic_find_by_arguments_count?(node) && dynamic_find_by_arguments_type?(node)
        end

        def dynamic_find_by_arguments_count?(node)
          column_keywords(node.method_name).size == node.arguments.size
        end

        def dynamic_find_by_arguments_type?(node)
          node.arguments.none? do |argument|
            IGNORED_ARGUMENT_TYPES.include?(argument.type)
          end
        end
      end
    end
  end
end
