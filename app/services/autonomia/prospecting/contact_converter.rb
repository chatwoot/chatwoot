class Autonomia::Prospecting::ContactConverter
  Result = Struct.new(:lead, :contact, :created, keyword_init: true)

  def initialize(lead:, user:)
    @lead = lead
    @account = lead.account
    @user = user
  end

  def perform
    return Result.new(lead: @lead, contact: @lead.contact, created: false) if @lead.contact.present?

    created = false
    contact = nil

    ActiveRecord::Base.transaction do
      contact = find_existing_contact || build_contact
      created = contact.new_record?
      enrich_contact(contact)
      contact.save!
      @lead.update!(contact: contact)
    end

    Result.new(lead: @lead.reload, contact: contact.reload, created: created)
  end

  private

  def find_existing_contact
    by_phone || by_identifier
  end

  def by_phone
    return if normalized_phone.blank?

    @account.contacts.find_by(phone_number: normalized_phone)
  end

  def by_identifier
    @account.contacts.find_by(identifier: prospecting_identifier)
  end

  def build_contact
    @account.contacts.new(
      contact_type: :lead,
      identifier: prospecting_identifier,
      name: @lead.name,
      phone_number: normalized_phone
    )
  end

  def enrich_contact(contact)
    contact.name = @lead.name if contact.name.blank?
    contact.phone_number = normalized_phone if contact.phone_number.blank? && normalized_phone.present?
    contact.identifier = prospecting_identifier if contact.identifier.blank?
    contact.location = contact.location.presence || location
    contact.additional_attributes = contact.additional_attributes.to_h.merge(additional_attributes).compact
    contact.custom_attributes = contact.custom_attributes.to_h.merge(custom_attributes).compact
  end

  def normalized_phone
    @normalized_phone ||= begin
      digits = @lead.phone.to_s.gsub(/\D/, '')
      phone = digits.present? ? "+#{digits}" : nil
      phone&.match?(/\A\+[1-9]\d{1,14}\z/) ? phone : nil
    end
  end

  def prospecting_identifier
    @prospecting_identifier ||= [
      'prospecting',
      @lead.provider,
      @lead.provider_place_id.presence || @lead.dedupe_key
    ].join(':')
  end

  def location
    [@lead.address, @lead.city, @lead.state, @lead.country].compact_blank.join(', ')
  end

  def additional_attributes
    {
      'company_name' => @lead.name,
      'city' => @lead.city,
      'state' => @lead.state,
      'country' => @lead.country,
      'description' => @lead.category,
      'website' => @lead.website,
      'source' => 'autonomia_prospecting'
    }
  end

  def custom_attributes
    {
      'autonomia_prospecting_lead_id' => @lead.id,
      'autonomia_prospecting_provider' => @lead.provider,
      'autonomia_prospecting_provider_place_id' => @lead.provider_place_id,
      'autonomia_prospecting_rating' => @lead.rating&.to_f,
      'autonomia_prospecting_reviews_count' => @lead.reviews_count,
      'autonomia_prospecting_converted_by_id' => @user&.id
    }
  end
end
