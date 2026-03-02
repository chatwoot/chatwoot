# frozen_string_literal: true

# Tool for updating contact details on the current conversation
# Used by AI agent when a customer wants to update their own information
#
# Example usage in agent:
#   chat.with_tools([UpdateContactTool])
#   response = chat.ask("Please update my name to John Smith")
#
class UpdateContactTool < BaseTool
  description 'Update the current contact\'s details. Use when the customer asks to change their name, email, ' \
              'address, or other profile information. Cannot change phone_number or identifier (identity anchors).'

  param :name, type: :string, desc: 'First name of the contact', required: false
  param :middle_name, type: :string, desc: 'Middle name of the contact', required: false
  param :last_name, type: :string, desc: 'Last name / family name of the contact', required: false
  param :email, type: :string, desc: 'Email address of the contact', required: false
  param :location, type: :string, desc: 'City or address of the contact', required: false
  param :country_code, type: :string, desc: 'ISO country code (e.g. US, SA, AE)', required: false
  param :custom_attributes, type: :object, desc: 'Key-value pairs to merge into custom attributes', required: false

  UPDATABLE_FIELDS = %i[name middle_name last_name email location country_code].freeze

  def execute(**params)
    validate_context!

    updates = build_updates(params)
    custom_attrs = normalize_custom_attributes(params[:custom_attributes])
    validation_error = validate_updates(updates, custom_attrs)

    return validation_error if validation_error
    return playground_response(updates, custom_attrs) if playground_mode?

    perform_update(updates, custom_attrs)
  rescue StandardError => e
    error_response("Failed to update contact: #{e.message}")
  end

  private

  def contact
    @contact ||= current_conversation.contact
  end

  def validate_updates(updates, custom_attrs)
    return error_response('No fields provided to update') if updates.empty? && custom_attrs.empty?
    return email_channel_error if updates.key?(:email) && email_inbox?
    return email_format_error(updates[:email]) if updates.key?(:email) && !valid_email?(updates[:email])

    nil
  end

  def build_updates(params)
    params.select { |_k, v| v.present? }.slice(*UPDATABLE_FIELDS)
  end

  def normalize_custom_attributes(attrs)
    return {} if attrs.blank?
    return attrs if attrs.is_a?(Hash)

    {}
  end

  def perform_update(updates, custom_attrs)
    old_values = snapshot_fields(updates, custom_attrs)

    updates[:custom_attributes] = contact.custom_attributes.merge(custom_attrs) if custom_attrs.present?
    contact.update!(updates)

    new_values = snapshot_fields(updates.except(:custom_attributes), custom_attrs)
    add_activity_message(old_values, new_values)

    success_response(
      updated: true,
      contact_id: contact.id,
      changed_fields: (updates.keys + (custom_attrs.present? ? [:custom_attributes] : [])).map(&:to_s),
      message: 'Contact updated successfully'
    )
  end

  def snapshot_fields(updates, custom_attrs)
    snapshot = {}
    updates.each_key { |field| snapshot[field] = contact.public_send(field) }
    custom_attrs.each_key { |key| snapshot["custom.#{key}"] = contact.custom_attributes[key.to_s] } if custom_attrs.present?
    snapshot
  end

  def add_activity_message(old_values, new_values)
    changes = old_values.filter_map do |field, old_val|
      new_val = new_values[field]
      next if old_val == new_val

      "#{field}: #{old_val.presence || '(empty)'} → #{new_val.presence || '(empty)'}"
    end

    return if changes.empty?

    current_conversation.messages.create!(
      account: current_account,
      inbox: current_conversation.inbox,
      message_type: :activity,
      content: "Contact updated by AI: #{changes.join(', ')}",
      private: true,
      content_attributes: { 'aloo_contact_update' => true }
    )
  end

  def email_inbox?
    current_conversation.inbox&.channel_type == 'Channel::Email'
  end

  def valid_email?(email)
    Devise.email_regexp.match?(email)
  end

  def email_channel_error
    error_response('Cannot update email on an email channel conversation — the email address is the identity anchor for this channel')
  end

  def email_format_error(email)
    error_response("Invalid email format: #{email}")
  end

  def playground_response(updates, custom_attrs)
    fields = (updates.keys + (custom_attrs.present? ? [:custom_attributes] : [])).map(&:to_s)
    success_response(
      updated: true,
      message: "[Playground] Would update contact fields: #{fields.join(', ')}",
      fields: fields
    )
  end
end
