module Conversations
  module Sort
    SORT_OPTIONS = {
      'last_activity_at_asc' => %w[sort_on_last_activity_at asc],
      'last_activity_at_desc' => %w[sort_on_last_activity_at desc],
      'created_at_asc' => %w[sort_on_created_at asc],
      'created_at_desc' => %w[sort_on_created_at desc],
      'priority_asc' => %w[sort_on_priority asc],
      'priority_desc' => %w[sort_on_priority desc],
      'waiting_since_asc' => %w[sort_on_waiting_since asc],
      'waiting_since_desc' => %w[sort_on_waiting_since desc],
      'priority_desc_created_at_asc' => %w[sort_on_priority_created_at desc],
      'unread' => %w[sort_on_unread desc],
      'last_message_from_asc' => %w[sort_on_last_message_from asc],
      'last_message_from_desc' => %w[sort_on_last_message_from desc],

      # Legacy aliases
      'latest' => %w[sort_on_last_activity_at desc],
      'sort_on_created_at' => %w[sort_on_created_at asc],
      'sort_on_priority' => %w[sort_on_priority desc],
      'sort_on_waiting_since' => %w[sort_on_waiting_since asc]
    }.with_indifferent_access.freeze

    CUSTOM_SORT_REGEX = /\A(-?)custom:(.+)\z/

    def self.apply(scope, sort_by, account:)
      match = sort_by.to_s.match(CUSTOM_SORT_REGEX)
      return apply_custom(scope, match, account) if match

      sort_method, sort_order = SORT_OPTIONS[sort_by] || SORT_OPTIONS['last_activity_at_desc']
      scope.public_send(sort_method, sort_order)
    end

    def self.apply_custom(scope, match, account)
      direction = match[1] == '-' ? 'DESC' : 'ASC'
      attribute_key = match[2]
      definition = account.custom_attribute_definitions
                         .conversation_attribute
                         .find_by(attribute_key: attribute_key)
      return scope.sort_on_last_activity_at('desc') unless definition

      numeric = definition.number? || definition.currency? || definition.percent? || definition.formula?
      scope.order_on_custom_attribute(attribute_key, direction, numeric: numeric)
    end
    private_class_method :apply_custom
  end
end
