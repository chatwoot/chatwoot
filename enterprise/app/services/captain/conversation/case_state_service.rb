class Captain::Conversation::CaseStateService
  STORAGE_KEY = 'captain_case_state'.freeze
  SCALAR_FIELDS = %w[active_issue customer_goal topic pending_action].freeze
  ARRAY_FIELDS = %w[known_facts missing_information attempted_steps].freeze
  MAX_VALUE_LENGTH = 500
  MAX_ARRAY_ITEMS = 20

  class << self
    def load(conversation)
      normalize(conversation.additional_attributes.to_h[STORAGE_KEY])
    end

    def persist(conversation, case_state, responding_to_message_id:)
      normalized_state = normalize(case_state)
      conversation = persisted_conversation(conversation)

      conversation.with_lock do
        next false unless conversation.pending?
        next false unless current_customer_message?(conversation, responding_to_message_id)

        attributes = conversation.additional_attributes.to_h.merge(
          STORAGE_KEY => normalized_state.merge('source_message_id' => responding_to_message_id)
        )
        conversation.update!(additional_attributes: attributes)
        true
      end
    end

    def clear(conversation)
      return false unless conversation.additional_attributes.to_h.key?(STORAGE_KEY)

      conversation = persisted_conversation(conversation)

      conversation.with_lock do
        attributes = conversation.additional_attributes.to_h
        next false unless attributes.key?(STORAGE_KEY)

        conversation.update!(additional_attributes: attributes.except(STORAGE_KEY))
        true
      end
    end

    private

    def persisted_conversation(conversation)
      conversation.class.find(conversation.id)
    end

    def current_customer_message?(conversation, responding_to_message_id)
      return false if responding_to_message_id.blank?

      conversation.messages.captain_response_triggering.maximum(:id) == responding_to_message_id
    end

    def normalize(case_state)
      state = case_state.to_h.stringify_keys

      SCALAR_FIELDS.index_with { |field| clean_value(state[field]) }
                   .merge(ARRAY_FIELDS.index_with { |field| clean_values(state[field]) })
    end

    def clean_values(values)
      Array(values).filter_map do |value|
        cleaned = clean_value(value)
        cleaned.presence
      end.first(MAX_ARRAY_ITEMS)
    end

    def clean_value(value)
      value.to_s.strip.first(MAX_VALUE_LENGTH)
    end
  end
end
