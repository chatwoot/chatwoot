# Chatwit: release the Socialwise Flow handoff when a conversation is resolved.
#
# The bot (Ana) is paused for a conversation by setting `socialwise_handoff_at`
# in additional_attributes (see Integrations::SocialwiseFlow::ProcessorService).
# That flag is only cleared on a platform-driven `resolve` action, which runs
# through the inbox hook. A human resolving the conversation in the UI/PWA never
# reaches that path, so the flag stays set and `bot_should_respond?` blocks the
# bot forever once the conversation reopens as `open` (inboxes wired through the
# socialwise_flow hook are not `active_bot?`, so reopen does not become pending).
#
# Resolving a conversation is the explicit "hand it back to the bot" gesture, so
# we clear the handoff flag here. Only conversations that actually carry the flag
# are touched, so non-Socialwise conversations are untouched.
class SocialwiseFlowListener < BaseListener
  def conversation_resolved(event)
    conversation, _account = extract_conversation_and_account(event)
    return if conversation.blank?

    attrs = conversation.additional_attributes || {}
    return if attrs['socialwise_handoff_at'].blank?

    conversation.update!(additional_attributes: attrs.except('socialwise_handoff_at', 'socialwise_handoff_by'))
    Rails.logger.info "[SOCIALWISE-FLOW] Cleared handoff flag on resolve for conversation #{conversation.id}"
  end
end
