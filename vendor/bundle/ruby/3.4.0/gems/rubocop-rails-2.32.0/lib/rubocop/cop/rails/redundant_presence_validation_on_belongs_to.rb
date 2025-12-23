# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Since Rails 5.0 the default for `belongs_to` is `optional: false`
      # unless `config.active_record.belongs_to_required_by_default` is
      # explicitly set to `false`. The presence validator is added
      # automatically, and explicit presence validation is redundant.
      #
      # @safety
      #   This cop's autocorrection is unsafe because it changes the default error message
      #   from "can't be blank" to "must exist".
      #
      # @example
      #   # bad
      #   belongs_to :user
      #   validates :user, presence: true
      #
      #   # bad
      #   belongs_to :user
      #   validates :user_id, presence: true
      #
      #   # bad
      #   belongs_to :author, foreign_key: :user_id
      #   validates :user_id, presence: true
      #
      #   # good
      #   belongs_to :user
      #
      #   # good
      #   belongs_to :author, foreign_key: :user_id
      #
      class RedundantPresenceValidationOnBelongsTo < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRailsVersion

        MSG = 'Remove explicit presence validation for %<association>s.'
        RESTRICT_ON_SEND = %i[validates].freeze

        # From https://github.com/rails/rails/blob/7a0bf93b9dd291c7f61121a41b3a813ac8857e6a/activemodel/lib/active_model/validations/validates.rb#L157-L159
        NON_VALIDATION_OPTIONS = %i[if unless on allow_blank allow_nil strict].freeze

        minimum_target_rails_version 5.0

        # @!method presence_validation?(node)
        #   Match a `validates` statement with a presence check
        #
        #   @example source that matches - by association
        #     validates :user, presence: true
        #
        #   @example source that matches - by association
        #     validates :name, :user, presence: true
        #
        #   @example source that matches - by a foreign key
        #     validates :user_id, presence: true
        #
        #   @example source that DOES NOT match - if condition
        #     validates :user_id, presence: true, if: condition
        #
        #   @example source that DOES NOT match - unless condition
        #     validates :user_id, presence: true, unless: condition
        #
        #   @example source that DOES NOT match - strict validation
        #     validates :user_id, presence: true, strict: true
        #
        #   @example source that DOES NOT match - custom strict validation
        #     validates :user_id, presence: true, strict: MissingUserError
        def_node_matcher :presence_validation?, <<~PATTERN
          (
            send nil? :validates
            (sym $_)+
            $[
              (hash <$(pair (sym :presence) true) ...>)         # presence: true
              !(hash <$(pair (sym :strict) {true const}) ...>)  # strict: true
              !(hash <$(pair (sym {:if :unless}) _) ...>)       # if: some_condition or unless: some_condition
            ]
          )
        PATTERN

        # @!method optional?(node)
        #   Match a `belongs_to` association with an optional option in a hash
        def_node_matcher :optional?, <<~PATTERN
          (send nil? :belongs_to _ ... #optional_option?)
        PATTERN

        # @!method optional_option?(node)
        #   Match an optional option in a hash
        def_node_matcher :optional_option?, <<~PATTERN
          {
            (hash <(pair (sym :optional) true) ...>)   # optional: true
            (hash <(pair (sym :required) false) ...>)  # required: false
          }
        PATTERN

        # @!method any_belongs_to?(node, association:)
        #   Match a class with `belongs_to` with no regard to `foreign_key` option
        #
        #   @example source that matches
        #     belongs_to :user
        #
        #   @example source that matches - regardless of `foreign_key`
        #     belongs_to :author, foreign_key: :user_id
        #
        #   @param node [RuboCop::AST::Node]
        #   @param association [Symbol]
        #   @return [Array<RuboCop::AST::Node>, nil] matching node
        def_node_matcher :any_belongs_to?, <<~PATTERN
          (begin
            <
              $(send nil? :belongs_to (sym %association) ...)
              ...
            >
          )
        PATTERN

        # @!method belongs_to?(node, key:, fk:)
        #   Match a class with a matching association, either by name or an explicit
        #   `foreign_key` option
        #
        #   @example source that matches - fk matches `foreign_key` option
        #     belongs_to :author, foreign_key: :user_id
        #
        #   @example source that matches - key matches association name
        #     belongs_to :user
        #
        #   @example source that does not match - explicit `foreign_key` does not match
        #     belongs_to :user, foreign_key: :account_id
        #
        #   @param node [RuboCop::AST::Node]
        #   @param key [Symbol] e.g. `:user`
        #   @param fk [Symbol] e.g. `:user_id`
        #   @return [Array<RuboCop::AST::Node>] matching nodes
        def_node_matcher :belongs_to?, <<~PATTERN
          (begin
            <
              ${
                #belongs_to_without_fk?(%key)         # belongs_to :user
                #belongs_to_with_a_matching_fk?(%fk)  # belongs_to :author, foreign_key: :user_id
              }
              ...
            >
          )
        PATTERN

        # @!method belongs_to_without_fk?(node, key)
        #   Match a matching `belongs_to` association, without an explicit `foreign_key` option
        #
        #   @param node [RuboCop::AST::Node]
        #   @param key [Symbol] e.g. `:user`
        #   @return [Array<RuboCop::AST::Node>] matching nodes
        def_node_matcher :belongs_to_without_fk?, <<~PATTERN
          {
            (send nil? :belongs_to (sym %1))        # belongs_to :user
            (send nil? :belongs_to (sym %1) !hash ...)  # belongs_to :user, -> { not_deleted }
            (send nil? :belongs_to (sym %1) !(hash <(pair (sym :foreign_key) _) ...>))
          }
        PATTERN

        # @!method belongs_to_with_a_matching_fk?(node, fk)
        #   Match a matching `belongs_to` association with a matching explicit `foreign_key` option
        #
        #   @example source that matches
        #     belongs_to :author, foreign_key: :user_id
        #
        #   @param node [RuboCop::AST::Node]
        #   @param fk [Symbol] e.g. `:user_id`
        #   @return [Array<RuboCop::AST::Node>] matching nodes
        def_node_matcher :belongs_to_with_a_matching_fk?, <<~PATTERN
          (send nil? :belongs_to ... (hash <(pair (sym :foreign_key) (sym %1)) ...>))
        PATTERN

        def on_send(node)
          presence_validation?(node) do |all_keys, options, presence|
            # If presence is the only validation option and other non-validation options
            # are present, removing it will cause rails to error.
            used_option_keys = options.keys.select(&:sym_type?).map(&:value)
            remaining_validations = used_option_keys - NON_VALIDATION_OPTIONS - [:presence]
            return if remaining_validations.none? && options.keys.length > 1

            keys = non_optional_belongs_to(node.parent, all_keys)
            return if keys.none?

            add_offense_and_correct(node, all_keys, keys, options, presence)
          end
        end

        private

        def add_offense_and_correct(node, all_keys, keys, options, presence)
          add_offense(presence, message: message_for(keys)) do |corrector|
            if options.children.one? # `presence: true` is the only option
              if keys == all_keys
                remove_validation(corrector, node)
              else
                remove_keys_from_validation(corrector, node, keys)
              end
            elsif keys == all_keys
              remove_presence_option(corrector, presence)
            else
              extract_validation_for_keys(corrector, node, keys, options)
            end
          end
        end

        def message_for(keys)
          display_keys = keys.map { |key| "`#{key}`" }.join('/')
          format(MSG, association: display_keys)
        end

        def non_optional_belongs_to(node, keys)
          keys.select do |key|
            belongs_to = belongs_to_for(node, key)
            belongs_to && !optional?(belongs_to)
          end
        end

        def belongs_to_for(model_class_node, key)
          if key.to_s.end_with?('_id')
            normalized_key = key.to_s.delete_suffix('_id').to_sym
            belongs_to?(model_class_node, key: normalized_key, fk: key)
          else
            any_belongs_to?(model_class_node, association: key)
          end
        end

        def remove_validation(corrector, node)
          corrector.remove(validation_range(node))
        end

        def remove_keys_from_validation(corrector, node, keys)
          keys.each do |key|
            key_node = node.arguments.find { |arg| arg.value == key }
            key_range = range_with_surrounding_space(
              range_with_surrounding_comma(key_node.source_range, :right),
              side: :right
            )
            corrector.remove(key_range)
          end
        end

        def remove_presence_option(corrector, presence)
          range = range_with_surrounding_comma(
            range_with_surrounding_space(presence.source_range, side: :left),
            :left
          )
          corrector.remove(range)
        end

        def extract_validation_for_keys(corrector, node, keys, options)
          indentation = ' ' * node.source_range.column
          options_without_presence = options.children.reject { |pair| pair.key.value == :presence }
          source = [
            indentation,
            'validates ',
            keys.map(&:inspect).join(', '),
            ', ',
            options_without_presence.map(&:source).join(', '),
            "\n"
          ].join

          remove_keys_from_validation(corrector, node, keys)
          corrector.insert_after(validation_range(node), source)
        end

        def validation_range(node)
          range_by_whole_lines(node.source_range, include_final_newline: true)
        end
      end
    end
  end
end
