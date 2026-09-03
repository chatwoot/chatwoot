# Classifies an inbound email sender into a triage lane and returns the
# conversation `additional_attributes` describing that lane. Returns an empty
# hash for the default lane so ordinary conversations stay untouched.
#
# Keys are strings on purpose: Conversation reads them back in before_create,
# where the jsonb attribute has not been round-tripped through the database yet.
class Email::SenderTriageService
  BYPASS_LISTS = %w[vip allowed].freeze

  # Local parts that only ever send machine-generated mail. `no-reply` variants are
  # matched after a separator too (`comments-noreply@`), but daemon addresses must be
  # exact so VERP-style `bounce+token@` senders from real systems are left alone.
  NOTIFICATION_SENDER_PATTERN = /\A(?:mailer-daemon|postmaster)\z|(?:\A|[-._+])(?:no[-._]?reply|do[-._]?not[-._]?reply)/i

  pattr_initialize [:account!, :channel!, :processed_mail!, :sender_email!]

  def perform
    attributes = {}
    attributes['sender_list'] = sender_list if sender_list.present?
    attributes.merge(filter_attributes)
  end

  private

  def sender_list
    return @sender_list if defined?(@sender_list)

    @sender_list = SenderListEntry.list_type_for(account: account, email: sender_email)
  end

  def filter_attributes
    return { 'filtered' => 'blocklist' } if sender_list == 'blocked'
    return {} if BYPASS_LISTS.include?(sender_list)
    return {} unless channel.newsletter_filter_enabled

    automated_mail_attributes || newsletter_attributes || {}
  end

  # Bounce is checked first because delivery reports routinely carry list/auto-reply
  # headers from the original message and would otherwise land in the wrong lane.
  def automated_mail_attributes
    return { 'filtered' => 'bounce' } if processed_mail.bounced?
    return { 'filtered' => 'auto_reply' } if processed_mail.auto_reply?

    { 'filtered' => 'notification' } if notification_sender?
  end

  def newsletter_attributes
    return unless processed_mail.newsletter?

    { 'filtered' => 'newsletter', 'newsletter_matches' => processed_mail.newsletter_matches }
  end

  def notification_sender?
    sender_email.to_s.split('@').first.to_s.match?(NOTIFICATION_SENDER_PATTERN)
  end
end
