class Ctwa::TrackedLinkAttributor
  CLICK_PATTERN = /#([A-Z2-9]{8})\b/
  CODE_PATTERN = /#([A-Z2-9]{6})\b/
  INFERRED_CLICK_WINDOW = 10.minutes

  def self.attribute!(conversation, message_content)
    new.attribute!(conversation, message_content)
  end

  def attribute!(conversation, message_content)
    return if conversation.blank? || message_content.blank?

    # Cheap regex gates FIRST: ordinary inbound messages must not pay attribution queries.
    content = message_content.to_s
    token = content.match(CLICK_PATTERN)&.[](1)
    return attribute_click_token!(conversation, token) if token.present?

    code = content.match(CODE_PATTERN)&.[](1)
    return attribute_code!(conversation, code) if code.present?

    attribute_inferred_click!(conversation)
  end

  private

  def attribute_code!(conversation, code)
    return unless first_inbound_message?(conversation)

    link = Ctwa::TrackedLink.for_account(conversation.account).find_by(code: code)
    return if link.blank?

    # CampaignBuilder derives `source` as meta_organic without ctwa_clid. For MVP the
    # canonical discriminator for trackable links is `source_type: tracked_link`.
    attributed = Ctwa::CampaignBuilder.attribute!(
      conversation,
      source_id: "link:#{code}",
      source_type: 'tracked_link',
      headline: link.name
    )
    return unless attributed

    link.increment!(:conversations_count) # rubocop:disable Rails/SkipsModelValidations
  end

  def attribute_click_token!(conversation, token)
    return unless first_inbound_message?(conversation)

    click = Ctwa::TrackedLinkClick.active
                                  .joins(:tracked_link)
                                  .includes(:tracked_link)
                                  .find_by(
                                    account_id: conversation.account_id,
                                    token: token,
                                    ctwa_tracked_links: { inbox_id: conversation.inbox_id }
                                  )
    return if click.blank?

    attribute_click!(conversation, click)
  end

  def attribute_inferred_click!(conversation)
    return unless eligible_for_inferred_click?(conversation)

    # Hot path order matters: memory gates run before click queries; message COUNT runs
    # only after a click candidate exists, and the LIMIT query only after that.
    scope = inferred_click_scope(conversation)
    return unless scope.exists?
    return unless first_inbound_message?(conversation)

    clicks = scope.limit(2).to_a
    return unless clicks.one?

    attribute_click!(conversation, clicks.first, inferred: true)
  end

  def attribute_click!(conversation, click, inferred: false)
    claimed = Ctwa::TrackedLinkClick.active.where(id: click.id).update_all(conversation_id: conversation.id) # rubocop:disable Rails/SkipsModelValidations
    return unless claimed == 1

    link = click.tracked_link
    return if link.blank?

    referral = click.params.to_h.merge(
      source_id: "click:#{click.token}",
      source_type: 'bridge',
      headline: link.name
    )
    referral[:inferred] = true if inferred

    attributed = Ctwa::CampaignBuilder.attribute!(
      conversation,
      referral.compact
    )
    return unless attributed

    link.increment!(:conversations_count) # rubocop:disable Rails/SkipsModelValidations
  end

  def inferred_click_scope(conversation)
    Ctwa::TrackedLinkClick.active
                          .joins(:tracked_link)
                          .includes(:tracked_link)
                          .where(account_id: conversation.account_id, ctwa_tracked_links: { inbox_id: conversation.inbox_id })
                          .where('ctwa_tracked_link_clicks.created_at >= ?', INFERRED_CLICK_WINDOW.ago)
                          .order(created_at: :desc)
  end

  def eligible_for_inferred_click?(conversation)
    return false if conversation.campaign_id.present? || conversation.additional_attributes.to_h['campaign'].present?
    return false if conversation.created_at < INFERRED_CLICK_WINDOW.ago

    true
  end

  def first_inbound_message?(conversation)
    conversation.messages.incoming.count == 1
  end
end
