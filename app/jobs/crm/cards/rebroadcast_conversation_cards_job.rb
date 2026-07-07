# Re-emits CRM_CARD_UPDATED for every card linked to a conversation whose
# card-relevant conversation data changed without a card upsert (campaign touch
# appended by Ctwa::CampaignBuilder, label_list changes seen by the CRM
# listener). Keeps board filters/pills consistent in realtime instead of only
# on refetch. Broadcaster already gates on Crm::Config.enabled? internally.
class Crm::Cards::RebroadcastConversationCardsJob < ApplicationJob
  queue_as :default

  def perform(conversation_id)
    # Link rows plus the crm_cards.conversation_id fallback: legacy cards can carry a
    # primary conversation without a crm_card_conversations row (payload builders and
    # filters honor that fallback, so the rebroadcast must too).
    card_ids = Crm::CardConversation.where(conversation_id: conversation_id).pluck(:card_id) |
               Crm::Card.where(conversation_id: conversation_id).pluck(:id)
    Crm::Card.where(id: card_ids).find_each do |card|
      Crm::Cards::Broadcaster.broadcast(card, ::Events::Types::CRM_CARD_UPDATED)
    end
  end
end
