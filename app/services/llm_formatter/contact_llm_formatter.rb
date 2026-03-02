class LLMFormatter::ContactLLMFormatter < LLMFormatter::DefaultLLMFormatter
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
    (core_attributes + custom_attributes_list).join("\n")
  end

  def core_attributes
    attrs = ["Name: #{@record.name}"]
    attrs << "Middle Name: #{@record.middle_name}" if @record.middle_name.present?
    attrs << "Last Name: #{@record.last_name}" if @record.last_name.present?
    attrs << "Contact Type: #{@record.contact_type}" if @record.contact_type.present?
    attrs.push("Email: #{@record.email}", "Phone: #{@record.phone_number}",
               "Location: #{@record.location}", "Country Code: #{@record.country_code}")
  end

  def custom_attributes_list
    @record.account.custom_attribute_definitions.with_attribute_model('contact_attribute').map do |attribute|
      "#{attribute.attribute_display_name}: #{@record.custom_attributes[attribute.attribute_key]}"
    end
  end
end
