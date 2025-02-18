class Contacts::BulkImportJob < ApplicationJob
  queue_as :default

  def perform(contacts_batch, account_id) # rubocop:disable Metrics/MethodLength
    results = {
      success: [],
      failed: []
    }

    contacts_batch.each do |contact_data|
      result = process_contact(contact_data, account_id)

      if result[:success]
        results[:success] << {
          contact: result[:contact],
          action: result[:action],
          message: result[:message]
        }
      else
        results[:failed] << {
          data: contact_data,
          error: result[:error]
        }
      end
    end

    # You might want to store these results or notify via email/webhook
    Rails.logger.info("Batch processed: #{results}")
  end

  private

  def process_contact(contact_data, account_id) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    return { success: false, error: 'Invalid data' } unless valid_contact?(contact_data)

    existing_contact = find_existing_contact(contact_data, account_id)

    if existing_contact
      contact_conversation = Conversation.find_by(contact_id: existing_contact.id, account_id: account_id)

      # If contact has both email, phone and conversations, return as is
      if existing_contact.phone_number.present? &&
         existing_contact.email.present? &&
         contact_conversation.present?
        return {
          success: true,
          contact: existing_contact,
          action: :unchanged,
          message: 'Contact already exists with all details'
        }
      end

      # Determine what fields to update based on existing data and conversations
      update_data = contact_data.dup
      update_data[:phone_number] = nil if existing_contact.phone_number.present? && contact_conversation.present?
      update_data[:email] = nil if existing_contact.email.present? && contact_conversation.present?

      update_contact(existing_contact, update_data)
    else
      create_contact(contact_data, account_id)
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def valid_contact?(contact_data)
    contact_data[:email].present? || contact_data[:phone_number].present?
  end

  def find_existing_contact(contact_data, account_id)
    existing_contact_email = contact_data[:email].present? ? Contact.find_by(account_id: account_id, email: contact_data[:email]) : nil
    existing_contact_phone = if contact_data[:phone_number].present?
                               Contact.find_by(account_id: account_id,
                                               phone_number: contact_data[:phone_number])
                             end

    existing_contact_email || existing_contact_phone
  end

  def update_contact(contact, contact_data)
    if contact.update(contact_data)
      {
        success: true,
        contact: contact,
        action: :updated,
        message: 'Contact updated successfully'
      }
    else
      {
        success: false,
        error: contact.errors.full_messages
      }
    end
  end

  def create_contact(contact_data, account_id)
    contact = Contact.new(contact_data.merge(account_id: account_id))

    if contact.save
      {
        success: true,
        contact: contact,
        action: :created,
        message: 'Contact created successfully'
      }
    else
      {
        success: false,
        error: contact.errors.full_messages
      }
    end
  end
end
