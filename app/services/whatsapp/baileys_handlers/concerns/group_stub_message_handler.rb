module Whatsapp::BaileysHandlers::Concerns::GroupStubMessageHandler # rubocop:disable Metrics/ModuleLength
  MEMBERSHIP_REQUEST_STUB = 'GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST_NON_ADMIN_ADD'.freeze
  ICON_CHANGE_STUB = 'GROUP_CHANGE_ICON'.freeze
  GROUP_CREATE_STUB = 'GROUP_CREATE'.freeze

  private

  def handle_membership_request_stub
    stub_params = @raw_message[:messageStubParameters]
    return if stub_params.blank?

    action = parse_membership_request_action(stub_params)
    return unless action

    group_jid = @raw_message[:key][:remoteJid]
    contact_name = resolve_membership_request_contact_name(stub_params)

    with_contact_lock(group_jid) do
      group_contact_inbox = find_or_create_group_contact_inbox_by_jid(group_jid)
      conversation = find_or_create_group_conversation(group_contact_inbox)
      create_group_activity(conversation, action, contact_name: contact_name)
      update_pending_join_requests(group_contact_inbox.contact, stub_params, action)
    end
  end

  def handle_icon_change_stub
    group_jid = @raw_message[:key][:remoteJid]
    participant_jid = @raw_message[:key][:participant]

    with_contact_lock(group_jid) do
      group_contact_inbox = find_or_create_group_contact_inbox_by_jid(group_jid)
      conversation = find_or_create_group_conversation(group_contact_inbox)
      author_name = resolve_author_name(participant_jid)
      create_group_activity(conversation, 'icon_changed', author_name: author_name)
      update_group_avatar(group_contact_inbox.contact)
    end
  end

  def handle_group_create_stub
    group_jid = @raw_message[:key][:remoteJid]
    group_name = @raw_message[:messageStubParameters]&.first

    with_contact_lock(group_jid) do
      group_contact_inbox = ::ContactInboxWithContactBuilder.new(
        source_id: group_jid.split('@').first,
        inbox: inbox,
        contact_attributes: {
          name: group_name || group_jid,
          identifier: group_jid,
          group_type: :group
        }
      ).perform

      group_contact = group_contact_inbox.contact
      was_group_left = group_contact.additional_attributes&.dig('group_left').present?
      reset_group_left_flag(group_contact)
      find_or_create_group_conversation(group_contact_inbox)
      handle_group_rejoin(group_contact) if was_group_left
      enqueue_group_sync(group_contact, force: was_group_left)
    end
  end

  def handle_group_rejoin(group_contact)
    add_inbox_contact_as_member(group_contact)
    dispatch_group_synced_event(group_contact)
  end

  def enqueue_group_sync(group_contact, force: false)
    Contacts::SyncGroupJob.set(wait: 5.seconds).perform_later(group_contact, force: force)
  end

  def add_inbox_contact_as_member(group_contact)
    inbox_phone = inbox.channel.phone_number&.delete('+')
    return if inbox_phone.blank?

    contact = Contact.where(account_id: inbox.account_id)
                     .where("REPLACE(phone_number, '+', '') = ?", inbox_phone)
                     .first
    return if contact.blank?

    add_group_member(group_contact, contact)
  end

  def reset_group_left_flag(group_contact)
    return unless group_contact.additional_attributes&.dig('group_left')

    new_attrs = (group_contact.additional_attributes || {}).merge('group_left' => false)
    group_contact.update!(additional_attributes: new_attrs)
  end

  def update_group_avatar(group_contact)
    provider = group_contact.group_channel&.provider_service
    return if provider.blank?

    provider.try_update_group_avatar(group_contact, force: true)
  rescue StandardError => e
    Rails.logger.error "[GROUP_ICON] Failed to update avatar for #{group_contact.identifier}: #{e.message}"
  end

  def parse_membership_request_action(stub_params)
    if stub_params.include?('created')
      'membership_request_created'
    elsif stub_params.include?('revoked')
      'membership_request_revoked'
    end
  end

  def resolve_membership_request_contact_name(stub_params)
    participant_data = JSON.parse(stub_params.first)
    lid = extract_jid_user(participant_data['lid'])
    phone = extract_jid_user(participant_data['pn'])

    find_contact_display_name(lid, phone) || format_fallback_name(lid, phone)
  rescue JSON::ParserError, TypeError
    extract_jid_user(@raw_message[:key][:participant])
  end

  def extract_jid_user(jid)
    jid&.split('@')&.first
  end

  def find_contact_display_name(lid, phone)
    source_id = lid || phone
    return unless source_id

    contact = inbox.contact_inboxes.find_by(source_id: source_id)&.contact
    return unless contact

    contact.name.presence || contact.phone_number
  end

  def format_fallback_name(lid, phone)
    phone ? "+#{phone}" : lid
  end

  def update_pending_join_requests(group_contact, stub_params, action)
    participant_data = JSON.parse(stub_params.first)
    lid = participant_data['lid']
    current_requests = group_contact.additional_attributes&.dig('pending_join_requests') || []
    updated = current_requests.reject { |r| r['jid'] == lid }
    updated << build_join_request_entry(participant_data) if action == 'membership_request_created'

    new_attrs = (group_contact.additional_attributes || {}).merge('pending_join_requests' => updated)
    group_contact.update!(additional_attributes: new_attrs)
  rescue JSON::ParserError, TypeError => e
    Rails.logger.error "[GROUP_STUB] Failed to update pending join requests: #{e.message}"
  end

  def build_join_request_entry(participant_data)
    contact = find_or_create_requester_contact(participant_data['lid'], participant_data['pn'])
    { 'jid' => participant_data['lid'], 'contact_id' => contact&.id, 'request_time' => Time.current.to_i.to_s }
  end

  def find_or_create_requester_contact(lid_jid, phone_jid)
    lid = extract_jid_user(lid_jid)
    phone = extract_jid_user(phone_jid)
    source_id = lid || phone
    return if source_id.blank?

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id, inbox: inbox,
      contact_attributes: requester_contact_attributes(lid, phone)
    ).perform
    contact_inbox&.contact
  end

  def requester_contact_attributes(lid, phone)
    { name: phone ? "+#{phone}" : lid, phone_number: ("+#{phone}" if phone), identifier: ("#{lid}@lid" if lid) }.compact
  end
end
