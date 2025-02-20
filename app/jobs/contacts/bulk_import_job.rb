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

    Rails.logger.info("Batch processed: #{results}")
  end

  private

  def process_contact(contact_data, account_id)
    return { success: false, error: 'Invalid data' } unless valid_contact?(contact_data)

    existing_contact = find_existing_contact(contact_data, account_id)
    existing_contact ? handle_existing_contact(existing_contact, contact_data, account_id) : create_contact(contact_data, account_id)
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def handle_existing_contact(contact, contact_data, account_id)
    return unchanged_contact_response(contact) if contact_complete?(contact, account_id)

    return unchanged_contact_response(contact) if contact_matches_data?(contact, contact_data)

    update_data = prepare_update_data(contact, contact_data, account_id)
    update_contact(contact, update_data)
  end

  def contact_complete?(contact, account_id)
    contact.phone_number.present? &&
      contact.email.present? &&
      Conversation.exists?(contact_id: contact.id, account_id: account_id)
  end

  def unchanged_contact_response(contact)
    {
      success: true,
      contact: contact,
      action: :unchanged,
      message: 'Contact already exists with all details'
    }
  end

  def prepare_update_data(contact, contact_data, account_id)
    update_data = contact_data.dup

    contact_has_conversation = Conversation.exists?(contact_id: contact.id, account_id: account_id)

    if contact_has_conversation
      if contact.email.present? && contact.phone_number.blank?
        update_data.delete(:email)
      elsif contact.phone_number.present? && contact.email.blank?
        update_data.delete(:phone_number)
      end
    end

    update_data.compact!
    update_data.reject! { |_, v| v.blank? }

    update_data
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

  def contact_matches_data?(contact, contact_data)
    contact.email.present? &&
      contact.phone_number.present? &&
      contact.email == contact_data[:email] &&
      contact.phone_number == contact_data[:phone_number]
  end
end
