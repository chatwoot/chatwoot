# frozen_string_literal: true

class Whatsapp::GroupService
  pattr_initialize [:conversation!, :group_options]

  def create_group
    return unless should_create_group?

    whapi_payload = build_group_payload
    response = send_create_group_request(whapi_payload)

    result = process_response(response)
    return unless result

    group_id = result[:group_id]
    group_conversation = result[:conversation]

    Rails.logger.info "[WHATSAPP GROUP] Group created: #{group_id}, with welcome message: #{welcome_message}"
    send_welcome_message(group_id, group_conversation) if group_id && group_conversation && welcome_message.present?
    group_id
  end

  private

  def should_create_group?
    inbox.auto_assignment_config&.dig('assignment_type') == 'group' &&
      conversation.assignee&.phone_number.present? &&
      conversation.contact&.phone_number.present?
  end

  def build_group_payload
    {
      subject: group_subject,
      participants: group_participants
    }
  end

  def group_subject
    return group_options[:group_name] if group_options.present? && group_options[:group_name].present?

    "Conversación ##{conversation.display_id} - #{inbox.name}"
  end

  def welcome_message
    return group_options[:welcome_message] if group_options.present? && group_options[:welcome_message].present?

    agent_name = conversation.assignee&.name || 'Agente'

    "¡Bienvenido\n\n" \
      "Este grupo se ha creado para brindarte un mejor servicio. #{agent_name} atenderá tus consultas a la brevedad."
  end

  def group_participants
    participants = []

    # Agregar número del agente asignado
    participants << format_phone_number(conversation.assignee.phone_number) if conversation.assignee&.phone_number.present?

    # Agregar número del cliente
    participants << format_phone_number(conversation.contact.phone_number) if conversation.contact&.phone_number.present?
    Rails.logger.info "[WHATSAPP GROUP] Participants: #{participants}"
    participants.compact.uniq
  end

  def send_create_group_request(payload)
    HTTParty.post(
      "#{whapi_api_url}/groups",
      headers: whapi_headers,
      body: payload.to_json
    )
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP GROUP] Error creating group: #{e.message}"
    nil
  end

  def process_response(response)
    return nil unless response&.success?

    parsed_response = parse_response_body(response.body)
    return nil unless parsed_response

    group_id = extract_group_id(parsed_response)
    return log_missing_group_id(response.body) unless group_id

    group_conversation = setup_group_conversation(group_id, parsed_response['participants'] || [])
    return nil unless group_conversation

    unprocessed = parsed_response['unprocessed_participants'].presence
    send_group_invites(group_id, unprocessed) if unprocessed

    { group_id: group_id, conversation: group_conversation }
  end

  def parse_response_body(body)
    parsed = JSON.parse(body)
    Rails.logger.info "[WHATSAPP GROUP] Group created response: #{parsed}"
    parsed
  rescue JSON::ParserError => e
    Rails.logger.error "[WHATSAPP GROUP] Error parsing response: #{e.message}"
    nil
  end

  def extract_group_id(parsed_response)
    group_id = parsed_response['group_id'] || parsed_response['id']
    Rails.logger.info "[WHATSAPP GROUP] Group created successfully: #{group_id}" if group_id
    group_id
  end

  def log_missing_group_id(response_body)
    Rails.logger.error "[WHATSAPP GROUP] No group_id in response: #{response_body}"
    nil
  end

  def send_welcome_message(group_id, group_conversation)
    message_payload = {
      to: group_id,
      body: welcome_message
    }

    response = HTTParty.post(
      "#{whapi_api_url}/messages/text",
      headers: whapi_headers,
      body: message_payload.to_json
    )

    Rails.logger.info "[WHATSAPP GROUP] Welcome message sent to group: #{group_id}, response: #{response.body}"

    # Save welcome message to database
    if response.success?
      parsed_response = JSON.parse(response.body)
      message_id = parsed_response.dig('message', 'id')

      if message_id
        create_welcome_message_record(group_conversation, message_id)
      end
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP GROUP] Error sending welcome message: #{e.message}"
  end

  def setup_group_conversation(group_id, participants)
    mapped_participants = map_participants_to_contacts(participants)
    group_contact_inbox = create_group_contact_inbox(group_id)
    group_conversation = create_group_conversation(group_contact_inbox, mapped_participants, group_id) if group_contact_inbox
    group_conversation
  end

  def create_group_conversation(group_contact_inbox, mapped_participants, group_id)
    return nil unless groups_inbox

    group_conversation = inbox.account.conversations.create!(
      inbox: groups_inbox,
      contact: conversation.contact,
      contact_inbox: group_contact_inbox,
      assignee: conversation.assignee,
      conversation_type: :whatsapp_group,
      additional_attributes: {
        whatsapp_group_id: group_id,
        whatsapp_group_name: group_subject,
        source_conversation_id: conversation.id,
        participants: mapped_participants
      }
    )

    Rails.logger.info "[WHATSAPP GROUP] Group conversation created: #{group_conversation.id} in groups inbox: #{groups_inbox.id}"
    group_conversation
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP GROUP] Error creating group conversation: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def create_group_contact_inbox(group_id)
    return nil unless groups_inbox

    # Crear ContactInbox para el grupo con el source_id del grupo en el inbox de grupos
    existing = ContactInbox.find_by(inbox_id: groups_inbox.id, source_id: group_id)
    return existing if existing

    group_contact_inbox = ContactInbox.create!(
      inbox_id: groups_inbox.id,
      contact_id: conversation.contact_id,
      source_id: group_id
    )

    Rails.logger.info "[WHATSAPP GROUP] ContactInbox created for group: #{group_id} in groups inbox: #{groups_inbox.id}"
    group_contact_inbox
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP GROUP] Error creating group contact inbox: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def map_participants_to_contacts(participants)
    # Mapear los participantes de Whapi con nuestros contactos locales
    participants.filter_map do |participant|
      whapi_id = participant['id']
      phone = participant['phone'] || extract_phone_from_whapi_id(whapi_id)
      rank = participant['rank']

      # Intentar encontrar el contacto por teléfono
      contact = find_contact_by_phone(phone)
      user = find_user_by_phone(phone)

      {
        'whapi_id' => whapi_id,
        'phone' => phone,
        'rank' => rank,
        'contact_id' => contact&.id,
        'user_id' => user&.id
      }
    end
  end

  def extract_phone_from_whapi_id(whapi_id)
    # Los IDs de Whapi tienen formato: 266507686797389@lid
    # Extraer solo la parte numérica
    whapi_id.to_s.split('@').first
  end

  def find_contact_by_phone(phone)
    return nil if phone.blank?

    formatted_phone = format_phone_number(phone)
    # Buscar contacto por número formateado (solo números)
    inbox.account.contacts.find do |contact|
      next if contact.phone_number.blank?

      format_phone_number(contact.phone_number) == formatted_phone
    end
  end

  def find_user_by_phone(phone)
    return nil if phone.blank?

    formatted_phone = format_phone_number(phone)
    # Buscar usuario por número formateado (solo números)
    inbox.account.users.find do |user|
      next if user.phone_number.blank?

      format_phone_number(user.phone_number) == formatted_phone
    end
  end

  def format_phone_number(phone)
    # Remover el + si existe y dejar solo números
    phone.to_s.gsub(/[^0-9]/, '')
  end

  def whapi_api_url
    ENV.fetch('WHAPI_GATE_URL', 'https://gate.whapi.cloud')
  end

  def whapi_headers
    {
      'Authorization' => "Bearer #{ENV.fetch('WHAPI_ADMIN_CHANNEL_TOKEN')}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  def create_welcome_message_record(group_conversation, message_id)
    Message.create!(
      account_id: group_conversation.account_id,
      inbox_id: group_conversation.inbox_id,
      conversation_id: group_conversation.id,
      message_type: :outgoing,
      content: welcome_message,
      source_id: message_id,
      sender: nil,
      content_type: 'text',
      content_attributes: {
        external_sender_name: ENV.fetch('WHATSAPP_ADMIN_NAME', 'Nauto Assistant'),
        external_sender_type: 'whatsapp_admin'
      }
    )

    Rails.logger.info "[WHATSAPP GROUP] Welcome message saved to conversation: #{group_conversation.id}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP GROUP] Error saving welcome message: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def send_group_invites(group_id, unprocessed_participants)
    invite_code = fetch_group_invite_code(group_id)
    return unless invite_code

    unprocessed_participants.each { |phone| send_invite_message(invite_code, phone) }
  end

  def fetch_group_invite_code(group_id)
    response = HTTParty.get(
      "#{whapi_api_url}/groups/#{group_id}/invite",
      headers: whapi_headers
    )

    unless response&.success?
      Rails.logger.error "[WHATSAPP GROUP] Failed to fetch invite code for group #{group_id}: #{response&.body}"
      return nil
    end

    JSON.parse(response.body)['invite_code']
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP GROUP] Error fetching invite code for group #{group_id}: #{e.message}"
    nil
  end

  def send_invite_message(invite_code, phone)
    agent_name = conversation.assignee&.name || 'Agente'
    message_payload = {
      to: phone,
      body: "En este grupo serás atendido por #{agent_name}",
      preview_type: 'none'
    }

    response = HTTParty.post(
      "#{whapi_api_url}/groups/link/#{invite_code}",
      headers: whapi_headers,
      body: message_payload.to_json
    )

    Rails.logger.info "[WHATSAPP GROUP] Invite sent to #{phone}, code: #{invite_code}, response: #{response.body}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP GROUP] Error sending invite to #{phone}: #{e.message}"
  end

  def inbox
    @inbox ||= conversation.inbox
  end

  def groups_inbox
    @groups_inbox ||= inbox.account.whatsapp_groups_inbox
  end
end
