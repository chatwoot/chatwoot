# Which conversation an inbound email belongs to when its headers say nothing.
#
# Every other channel asks this question through the inbox's reopen policy: WhatsApp, Telegram,
# Line, Twilio, SMS, TikTok, Instagram and Facebook all run `identity || inbox policy || create`.
# Email only ran `headers || create`, so a customer who composes a fresh message instead of
# replying opened a second conversation about a case that was still open, and neither side of the
# split knew about the other. The headers still win: they are positive proof of which thread this
# is, and the policy only decides when they are silent.
#
# Off by default, per inbox, because the answer is not universal. A support desk that runs several
# simultaneous cases per client wants one conversation per thread, which is what the default keeps.
class Email::ConversationPolicy
  # Returns the conversation this contact's mail should continue, or nil to let the caller create
  # one. Scoped to the contact rather than the contact_inbox, mirroring
  # Whatsapp::Session::Inbound::ConversationFinder#conversation_by_inbox_config: one person can
  # hold several contact_inboxes in the same inbox, and reuse has to see all of them.
  def self.existing_for(inbox:, contact:)
    return if contact.blank?
    return unless inbox.channel.try(:continue_open_conversation)

    conversations = contact.conversations.where(inbox_id: inbox.id)
    # Same meaning it carries on every other channel: locked takes the last thread whatever its
    # state, unlocked continues only a case nobody has closed yet.
    return conversations.last if inbox.lock_to_single_conversation

    conversations.where.not(status: :resolved).last
  end
end
