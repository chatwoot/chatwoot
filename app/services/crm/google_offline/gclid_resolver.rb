module Crm::GoogleOffline::GclidResolver
  Result = Data.define(:gclid, :conversation_id)

  module_function

  def resolve(card)
    resolve_with_conversation(card)&.gclid
  end

  def resolve_with_conversation(card)
    latest = conversations_for(card).flat_map { |conversation| touches_for(conversation) }
                                    .max_by { |touch| [touch[:touched_at], touch[:conversation_id], touch[:position]] }
    Result.new(gclid: latest[:gclid], conversation_id: latest[:conversation_id]) if latest
  end

  def conversations_for(card)
    return [] if card.blank?

    (card.linked_conversations.to_a + [card.primary_conversation]).compact.uniq(&:id)
  end

  def touches_for(conversation)
    Array(conversation.additional_attributes&.dig('campaign_touches')).filter_map.with_index do |touch, position|
      next unless touch.is_a?(Hash) && touch['gclid'].present?

      {
        gclid: touch['gclid'],
        touched_at: touch['touched_at'].to_s,
        conversation_id: conversation.id,
        position: position
      }
    end
  end
end
