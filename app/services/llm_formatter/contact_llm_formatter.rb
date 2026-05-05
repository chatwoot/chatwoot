class LlmFormatter::ContactLlmFormatter < LlmFormatter::DefaultLlmFormatter
  def format(*)
    sections = []
    sections << "Contact ID: ##{@record.id}"
    sections << 'Contact Attributes:'
    sections << build_attributes
    sections << 'Contact Notes:'
    sections << if @record.notes.any?
                  build_notes
                else
                  'No notes for this contact'
                end

    sections.join("\n")
  end

  private

  def build_notes
    @record.notes.all.map { |note| " - #{note.content}" }.join("\n")
  end

  def build_attributes
    attributes = base_attributes
    @record.account.custom_attribute_definitions.with_attribute_model('contact_attribute').each do |attribute|
      attributes << "#{attribute.attribute_display_name}: #{@record.custom_attributes[attribute.attribute_key]}"
    end
    attributes.join("\n")
  end

  def base_attributes
    [
      "Name: #{@record.name}",
      "Email: #{@record.email}",
      *additional_email_attributes,
      "Phone: #{@record.phone_number}",
      *additional_phone_attributes,
      "Location: #{@record.location}",
      "Country Code: #{@record.country_code}"
    ]
  end

  def additional_email_attributes
    additional_emails = @record.additional_emails
    return [] if additional_emails.empty?

    ["Additional emails: #{additional_emails.join(', ')}"]
  end

  def additional_phone_attributes
    additional_phones = @record.additional_phones
    return [] if additional_phones.empty?

    ["Additional phones: #{additional_phones.join(', ')}"]
  end
end
