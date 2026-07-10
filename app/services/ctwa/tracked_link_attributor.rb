class Ctwa::TrackedLinkAttributor
  CODE_PATTERN = /#([A-Z2-9]{6})\b/

  def self.attribute!(conversation, message_content)
    new.attribute!(conversation, message_content)
  end

  def attribute!(conversation, message_content)
    return if conversation.blank? || message_content.blank?

    # Cheap regex gate FIRST: ordinary inbound messages must not pay the
    # first-message COUNT query — only code-bearing ones proceed.
    code = message_content.to_s.match(CODE_PATTERN)&.[](1)
    return if code.blank?
    return unless first_inbound_message?(conversation)

    link = Ctwa::TrackedLink.for_account(conversation.account).find_by(code: code)
    return if link.blank?

    # CampaignBuilder derives `source` as meta_organic without ctwa_clid. For MVP the
    # canonical discriminator for trackable links is `source_type: tracked_link`.
    Ctwa::CampaignBuilder.attribute!(
      conversation,
      source_id: "link:#{code}",
      source_type: 'tracked_link',
      headline: link.name
    )
    link.increment!(:conversations_count) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  def first_inbound_message?(conversation)
    conversation.messages.incoming.count == 1
  end
end
