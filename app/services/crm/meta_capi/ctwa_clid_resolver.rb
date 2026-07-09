# Resolves the ctwa_clid (Click-to-WhatsApp click id) that attributes a card back to a
# Meta ad click. Written by Ctwa::CampaignBuilder onto the card's primary conversation:
# the `campaign` origin holds the first touch, `campaign_touches` the later clicks.
#
# Prefers the origin clid; falls back to the most recent touch that carries one.
# Returns nil when the conversation has no CTWA signal (no attribution possible).
module Crm::MetaCapi::CtwaClidResolver
  module_function

  def resolve(card)
    conversation = card&.primary_conversation
    return if conversation.blank?

    attrs = conversation.additional_attributes || {}
    from_campaign(attrs) || from_touches(attrs)
  end

  def from_campaign(attrs)
    attrs.dig('campaign', 'ctwa_clid').presence
  end

  def from_touches(attrs)
    Array(attrs['campaign_touches']).filter_map { |touch| touch['ctwa_clid'].presence }.last
  end
end
