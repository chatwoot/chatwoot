class Campaigns::AudiencePreviewService
  pattr_initialize [:account!, :inbox!, :audience]

  def perform
    contacts = tagged_contacts
    total = contacts.count
    with_phone = contacts.where.not(phone_number: [nil, '']).count

    {
      total: total,
      with_phone: with_phone,
      eligible: eligible_count(contacts, with_phone)
    }
  end

  private

  def audience_label_titles
    audience_items = Array(audience)
    label_ids = audience_items.filter_map { |item| (item[:id] || item['id']).presence }
    return [] if label_ids.blank?

    account.labels.where(id: label_ids).pluck(:title)
  end

  def tagged_contacts
    titles = audience_label_titles
    return account.contacts.none if titles.blank?

    account.contacts.tagged_with(titles, any: true)
  end

  # Mirrors one-off WA/SMS send filters: contacts with a phone number.
  def eligible_count(contacts, with_phone)
    return with_phone if phone_channel?

    contacts.count
  end

  def phone_channel?
    ['Twilio SMS', 'Sms', 'Whatsapp'].include?(inbox.inbox_type)
  end
end
