# Classifies an inbound email sender into one of three lanes and returns the
# conversation `additional_attributes` describing that lane. Returns an empty
# hash for the default lane so ordinary conversations stay untouched.
#
# Keys are strings on purpose: Conversation reads them back in before_create,
# where the jsonb attribute has not been round-tripped through the database yet.
class Email::SenderTriageService
  BYPASS_LISTS = %w[vip allowed].freeze

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
    return {} unless channel.newsletter_filter_enabled && processed_mail.newsletter?

    { 'filtered' => 'newsletter', 'newsletter_matches' => processed_mail.newsletter_matches }
  end
end
