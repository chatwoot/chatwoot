class Conversations::InheritContactLabelsService
  def initialize(conversation:)
    @conversation = conversation
  end

  def perform
    contact = @conversation.contact
    return if contact.blank?

    contact_labels = Array(contact.label_list).map(&:to_s).compact_blank
    return if contact_labels.blank?

    existing_down = Array(@conversation.label_list).map { |label| label.to_s.downcase }
    missing = contact_labels.reject { |label| existing_down.include?(label.downcase) }
    return if missing.blank?

    @conversation.add_labels(missing)
  end
end
