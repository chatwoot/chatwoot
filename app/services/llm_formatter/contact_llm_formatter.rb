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
    @record.notes.latest.includes(:user).map do |note|
      author_name = note.created_by&.name || 'Unknown'
      timestamp = note.created_at&.iso8601
      " - #{note.content} (Author: #{author_name}; Source: #{note.source}; Created: #{timestamp})"
    end.join("\n")
  end

  def build_attributes
    attributes = []
    attributes << "Name: #{@record.name}"
    attributes << "Email: #{@record.email}"
    attributes << "Phone: #{@record.phone_number}"
    attributes << "Location: #{@record.location}"
    attributes << "Country Code: #{@record.country_code}"
    @record.account.custom_attribute_definitions.with_attribute_model('contact_attribute').each do |attribute|
      attributes << "#{attribute.attribute_display_name}: #{@record.custom_attributes[attribute.attribute_key]}"
    end
    attributes.join("\n")
  end
end
