class Whatsapp::Providers::WhatsappBaileysService < Whatsapp::Providers::BaseService # rubocop:disable Metrics/ClassLength
  include BaileysHelper

  class MessageContentTypeNotSupported < StandardError; end
  class ProviderUnavailableError < StandardError; end
  class GroupParticipantNotAllowedError < StandardError; end

  DEFAULT_CLIENT_NAME = ENV.fetch('BAILEYS_PROVIDER_DEFAULT_CLIENT_NAME', nil)
  DEFAULT_URL = ENV.fetch('BAILEYS_PROVIDER_DEFAULT_URL', nil)
  DEFAULT_API_KEY = ENV.fetch('BAILEYS_PROVIDER_DEFAULT_API_KEY', nil)

  def self.groups_enabled?
    ENV.fetch('BAILEYS_WHATSAPP_GROUPS_ENABLED', 'false') == 'true'
  end

  def self.status
    if DEFAULT_URL.blank? || DEFAULT_API_KEY.blank?
      raise ProviderUnavailableError, 'Missing BAILEYS_PROVIDER_DEFAULT_URL or BAILEYS_PROVIDER_DEFAULT_API_KEY setup'
    end

    response = HTTParty.get(
      "#{DEFAULT_URL}/status",
      headers: { 'x-api-key' => DEFAULT_API_KEY }
    )

    unless response.success?
      Rails.logger.error response.body
      raise ProviderUnavailableError, 'Baileys API is unavailable'
    end

    response.parsed_response.deep_symbolize_keys
  rescue ProviderUnavailableError
    raise
  rescue StandardError => e
    Rails.logger.error e.message
    raise ProviderUnavailableError, 'Baileys API is unavailable'
  end

  def setup_channel_provider
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}",
      headers: api_headers,
      body: {
        clientName: DEFAULT_CLIENT_NAME,
        webhookUrl: whatsapp_channel.inbox.callback_webhook_url,
        webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token'],
        # TODO: Remove on Baileys v2, default will be false
        includeMedia: false,
        groupsEnabled: self.class.groups_enabled?
      }.compact.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def disconnect_channel_provider
    response = HTTParty.delete(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}",
      headers: api_headers
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def send_message(recipient_id, message)
    @message = message
    @recipient_id = recipient_id

    if @message.content_attributes[:is_reaction]
      @message_content = reaction_message_content
    elsif @message.attachments.present?
      @message_content = attachment_message_content.merge(reply_context)
    elsif @message.outgoing_content.present?
      @message_content = { text: @message.outgoing_content }.merge(reply_context)
      merge_mention_data
    else
      @message.update!(is_unsupported: true)
      return
    end

    send_message_request
  end

  def send_template(phone_number, template_info); end

  def sync_templates; end

  def allow_group_creation?
    true
  end

  def create_group(subject, participants)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-create",
      headers: api_headers,
      body: { subject: subject, participants: participants }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.deep_symbolize_keys
  end

  def update_group_subject(group_jid, subject)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-subject",
      headers: api_headers,
      body: { jid: group_jid, subject: subject }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def update_group_description(group_jid, description)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-description",
      headers: api_headers,
      body: { jid: group_jid, description: description }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def update_group_picture(group_jid, image_base64)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/update-profile-picture",
      headers: api_headers,
      body: { jid: group_jid, image: image_base64 }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def update_group_participants(group_jid, participants, action)
    Array(participants).each do |participant|
      response = HTTParty.post(
        "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-participants",
        headers: api_headers,
        body: { jid: group_jid, participant: participant, action: action }.to_json
      )

      raise ProviderUnavailableError unless process_response(response)

      check_participant_errors(response, action)
    end
  end

  def group_invite_code(group_jid)
    response = HTTParty.get(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-invite-code",
      headers: api_headers,
      query: { jid: group_jid },
      format: :json
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.dig('data', 'inviteCode')
  end

  def revoke_group_invite(group_jid)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-revoke-invite",
      headers: api_headers,
      body: { jid: group_jid }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.dig('data', 'inviteCode')
  end

  def group_join_requests(group_jid)
    response = HTTParty.get(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-request-participants-list",
      headers: api_headers,
      query: { jid: group_jid },
      format: :json
    )

    return [] if response.code == 403

    raise ProviderUnavailableError unless process_response(response)

    parsed = response.parsed_response
    parsed.is_a?(Array) ? parsed : (parsed&.dig('data') || [])
  end

  def handle_group_join_requests(group_jid, participants, action)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-request-participants-update",
      headers: api_headers,
      body: { jid: group_jid, participants: participants, action: action }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def group_leave(group_jid)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-leave",
      headers: api_headers,
      body: { jid: group_jid }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  PROPERTY_TO_SETTING = {
    ['announce', true] => 'announcement',
    ['announce', false] => 'not_announcement',
    ['restrict', true] => 'locked',
    ['restrict', false] => 'unlocked'
  }.freeze

  def group_setting_update(group_jid, property, enabled)
    setting = PROPERTY_TO_SETTING[[property, enabled]]
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-setting-update",
      headers: api_headers,
      body: { jid: group_jid, setting: setting }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def group_join_approval_mode(group_jid, mode)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-join-approval-mode",
      headers: api_headers,
      body: { jid: group_jid, mode: mode }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def group_member_add_mode(group_jid, mode)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-member-add-mode",
      headers: api_headers,
      body: { jid: group_jid, mode: mode }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def sync_group(conversation, soft: false)
    group_contact = conversation.contact

    return true if group_contact.additional_attributes&.dig('group_left')

    inbox = conversation.inbox

    metadata = group_metadata(group_contact.identifier)
    raise ProviderUnavailableError, 'Could not fetch group metadata' if metadata.blank?

    update_group_contact_info(group_contact, metadata)
    persist_group_settings(group_contact, metadata)
    persist_invite_code(group_contact) unless soft
    persist_pending_join_requests(group_contact, inbox) unless soft
    try_update_group_avatar(group_contact) unless soft

    participant_contacts = build_participant_contacts(metadata[:participants], inbox, skip_avatars: soft)
    sync_group_members(group_contact, participant_contacts)
    persist_sync_status(group_contact)

    true
  end

  def media_url(media_id)
    "#{provider_url}/media/#{media_id}"
  end

  def api_headers
    { 'x-api-key' => api_key, 'Content-Type' => 'application/json' }
  end

  def validate_provider_config?
    response = HTTParty.get(
      "#{provider_url}/status/auth",
      headers: api_headers
    )

    process_response(response)
  end

  def toggle_typing_status(typing_status, recipient_id:, **)
    @recipient_id = recipient_id
    status_map = {
      Events::Types::CONVERSATION_TYPING_ON => 'composing',
      Events::Types::CONVERSATION_RECORDING => 'recording',
      Events::Types::CONVERSATION_TYPING_OFF => 'paused'
    }

    response = HTTParty.patch(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/presence",
      headers: api_headers,
      body: {
        toJid: remote_jid,
        type: status_map[typing_status]
      }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def update_presence(status)
    status_map = {
      'online' => 'available',
      'offline' => 'unavailable',
      'busy' => 'unavailable'
    }

    response = HTTParty.patch(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/presence",
      headers: api_headers,
      body: {
        type: status_map[status]
      }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def read_messages(messages, recipient_id:, **)
    @recipient_id = recipient_id

    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/read-messages",
      headers: api_headers,
      body: {
        keys: messages.map { |message| message_key_for(message) }
      }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def unread_message(recipient_id, message)
    @recipient_id = recipient_id

    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/chat-modify",
      headers: api_headers,
      body: {
        jid: remote_jid,
        mod: {
          markRead: false,
          lastMessages: [{
            key: message_key_for(message),
            messageTimestamp: message.content_attributes[:external_created_at]
          }]
        }
      }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def received_messages(recipient_id, messages)
    @recipient_id = recipient_id

    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/send-receipts",
      headers: api_headers,
      body: {
        keys: messages.map { |message| message_key_for(message) }
      }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def get_profile_pic(jid)
    response = HTTParty.get(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/profile-picture-url",
      headers: api_headers,
      query: { jid: jid },
      format: :json
    )

    return nil unless process_response(response)

    response.parsed_response
  end

  def group_metadata(group_jid)
    response = HTTParty.get(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-metadata",
      headers: api_headers,
      query: { jid: group_jid },
      format: :json
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.deep_symbolize_keys
  end

  def on_whatsapp(recipient_id)
    @recipient_id = recipient_id

    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/on-whatsapp",
      headers: api_headers,
      body: {
        jids: [remote_jid]
      }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    result = response.parsed_response
    result = result.is_a?(Array) ? result : result&.dig('data')
    result&.first || { 'jid' => remote_jid, 'exists' => false }
  end

  def delete_message(recipient_id, message)
    @recipient_id = recipient_id

    response = HTTParty.delete(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/messages",
      headers: api_headers,
      body: {
        jid: remote_jid,
        key: message_key_for(message)
      }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def edit_message(recipient_id, message, new_content)
    @recipient_id = recipient_id

    response = HTTParty.patch(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/messages",
      headers: api_headers,
      body: {
        jid: remote_jid,
        key: message_key_for(message),
        messageContent: { text: new_content }
      }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  private

  def provider_url
    whatsapp_channel.provider_config['provider_url'].presence || DEFAULT_URL
  end

  def api_key
    whatsapp_channel.provider_config['api_key'].presence || DEFAULT_API_KEY
  end

  def reaction_message_content
    reply_to = Message.find(@message.in_reply_to)
    {
      react: {
        key: message_key_for(reply_to),
        text: @message.outgoing_content
      }
    }
  end

  def reply_context
    reply_to_external_id = @message.content_attributes[:in_reply_to_external_id]
    return {} if reply_to_external_id.blank?

    reply_to_message = @message.conversation.messages.find_by(source_id: reply_to_external_id)
    return {} unless reply_to_message

    {
      quotedMessage: {
        key: message_key_for(reply_to_message),
        message: quoted_message_content(reply_to_message)
      }
    }
  end

  def message_key_for(message)
    {
      id: message.source_id,
      remoteJid: remote_jid,
      fromMe: message.message_type == 'outgoing',
      participant: group_participant_jid(message)
    }.compact
  end

  def group_participant_jid(message)
    return unless remote_jid.ends_with?('@g.us')
    return if message.message_type == 'outgoing'

    message.sender&.identifier
  end

  def quoted_message_content(message)
    if message.attachments.present?
      attachment = message.attachments.first
      case attachment.file_type
      when 'image'
        { imageMessage: { caption: message.content } }
      when 'video'
        { videoMessage: { caption: message.content } }
      when 'audio'
        { audioMessage: {} }
      when 'file'
        { documentMessage: { caption: message.content, fileName: attachment.file.filename.to_s } }
      else
        { conversation: message.content.to_s }
      end
    else
      { conversation: message.content.to_s }
    end
  end

  def attachment_message_content # rubocop:disable Metrics/MethodLength
    attachment = @message.attachments.first
    buffer = attachment_to_base64(attachment)

    content = {
      fileName: attachment.file.filename,
      caption: @message.outgoing_content
    }
    case attachment.file_type
    when 'image'
      content[:image] = buffer
    when 'audio'
      content[:audio] = buffer
      content[:ptt] = attachment.meta&.dig('is_recorded_audio')
    when 'file'
      content[:document] = buffer
      content[:mimetype] = attachment.file.content_type
    when 'sticker'
      content[:sticker] = buffer
    when 'video'
      content[:video] = buffer
    end

    content.compact
  end

  def send_message_request
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/send-message",
      headers: api_headers,
      body: {
        jid: remote_jid,
        messageContent: @message_content
      }.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    update_external_created_at(response)
    response.parsed_response.dig('data', 'key', 'id')
  end

  def process_response(response)
    Rails.logger.error response.body unless response.success?
    response.success?
  end

  def check_participant_errors(response, action)
    return unless action.in?(%w[demote remove])

    results = response.parsed_response
    return unless results.is_a?(Array)

    failed = results.find { |r| r['status'].to_s == '406' }
    return if failed.blank?

    raise GroupParticipantNotAllowedError, 'group_creator_not_modifiable'
  end

  def merge_mention_data
    return if @message.content.blank?

    mention_data = Whatsapp::MentionConverterService.extract_mentions_for_whatsapp(@message.content, whatsapp_channel.account)
    @message_content.merge!(mention_data) if mention_data.present?

    # Replace @DisplayName with @lid/@phone in text so Baileys can match mentions
    @message_content[:text] = Whatsapp::MentionConverterService.replace_mentions_in_outgoing_text(
      @message.content, @message_content[:text], whatsapp_channel.account
    )
  end

  def remote_jid
    return @recipient_id if @recipient_id.ends_with?('@lid')
    return @recipient_id if @recipient_id.ends_with?('@g.us')

    "#{@recipient_id.delete('+')}@s.whatsapp.net"
  end

  def update_external_created_at(response)
    timestamp = response.parsed_response.dig('data', 'messageTimestamp')
    return unless timestamp

    external_created_at = baileys_extract_message_timestamp(timestamp)
    @message.update!(external_created_at: external_created_at)
  end

  def build_participant_contacts(participants, inbox, skip_avatars: false)
    return [] if participants.blank?

    participants.filter_map do |participant|
      contact = find_or_create_participant_contact(participant, inbox)
      next if contact.blank?

      try_update_participant_avatar(contact) unless skip_avatars
      { contact: contact, admin: participant[:admin] }
    end
  end

  def update_group_contact_info(group_contact, metadata)
    update_params = {}
    update_params[:name] = metadata[:subject] if metadata[:subject].present? && group_contact.name != metadata[:subject]

    new_attrs = (group_contact.additional_attributes || {}).merge(
      'description' => metadata[:desc].presence,
      'owner' => metadata[:owner],
      'owner_pn' => metadata[:ownerPn].presence
    )
    update_params[:additional_attributes] = new_attrs if new_attrs != group_contact.additional_attributes

    group_contact.update!(update_params) if update_params.present?
  end

  def sync_group_members(group_contact, participant_contacts)
    return if participant_contacts.blank?

    new_contact_ids = participant_contacts.filter_map do |entry|
      role = entry[:admin].in?(%w[admin superadmin]) ? :admin : :member
      member = GroupMember.find_or_initialize_by(group_contact: group_contact, contact: entry[:contact])
      member.assign_attributes(role: role, is_active: true)
      member.save! if member.changed?
      entry[:contact].id
    end

    group_contact.group_memberships.active.where.not(contact_id: new_contact_ids).find_each do |member|
      member.update!(is_active: false)
    end
  end

  TRACKED_GROUP_SETTINGS = {
    announce: 'announce',
    restrict: 'restrict',
    joinApprovalMode: 'join_approval_mode',
    memberAddMode: 'member_add_mode'
  }.freeze

  def persist_group_settings(group_contact, metadata)
    settings = TRACKED_GROUP_SETTINGS.each_with_object({}) do |(api_key, attr_key), hash|
      hash[attr_key] = metadata[api_key] if metadata.key?(api_key)
    end
    return if settings.blank?

    new_attrs = (group_contact.additional_attributes || {}).merge(settings)
    group_contact.update!(additional_attributes: new_attrs) if new_attrs != group_contact.additional_attributes
  end

  def persist_sync_status(group_contact)
    new_attrs = (group_contact.additional_attributes || {}).merge(
      'group_last_synced_at' => Time.current.to_i,
      'group_left' => false
    )
    group_contact.update!(additional_attributes: new_attrs) if new_attrs != group_contact.additional_attributes
  end

  def persist_invite_code(group_contact)
    code = group_invite_code(group_contact.identifier)
    return if code.blank?

    new_attrs = (group_contact.additional_attributes || {}).merge('invite_code' => code)
    group_contact.update!(additional_attributes: new_attrs) if new_attrs != group_contact.additional_attributes
  rescue StandardError => e
    Rails.logger.error "Failed to fetch invite code for group #{group_contact.identifier}: #{e.message}"
  end

  def persist_pending_join_requests(group_contact, inbox)
    raw_requests = group_join_requests(group_contact.identifier)
    requests = raw_requests.filter_map do |req|
      contact = find_or_create_participant_contact({ id: req['jid'], phoneNumber: req['phone_number'] }, inbox)
      next if contact.blank?

      { 'jid' => req['jid'], 'contact_id' => contact.id, 'request_time' => req['request_time'] }
    end

    new_attrs = (group_contact.additional_attributes || {}).merge('pending_join_requests' => requests)
    group_contact.update!(additional_attributes: new_attrs) if new_attrs != group_contact.additional_attributes
  rescue StandardError => e
    Rails.logger.error "Failed to fetch pending join requests for group #{group_contact.identifier}: #{e.message}"
  end

  public

  def try_update_group_avatar(group_contact, force: false)
    if force
      reset_avatar_state(group_contact)
    elsif group_contact.avatar.attached?
      return
    end

    response = get_profile_pic(group_contact.identifier)
    profile_pic_url = response&.dig('data', 'profilePictureUrl')
    ::Avatar::AvatarFromUrlJob.perform_later(group_contact, profile_pic_url) if profile_pic_url
  rescue StandardError => e
    Rails.logger.error "Failed to update avatar for group #{group_contact.identifier}: #{e.message}"
  end

  private

  def reset_avatar_state(group_contact)
    group_contact.avatar.purge if group_contact.avatar.attached?
    attrs = (group_contact.additional_attributes || {}).except('last_avatar_sync_at', 'avatar_url_hash')
    group_contact.update_columns(additional_attributes: attrs) # rubocop:disable Rails/SkipsModelValidations
  end

  def try_update_participant_avatar(contact)
    return if contact.avatar.attached?

    phone = contact.phone_number&.delete('+')
    return if phone.blank?

    profile_pic_url = fetch_profile_picture_url(phone)
    ::Avatar::AvatarFromUrlJob.perform_later(contact, profile_pic_url) if profile_pic_url
  rescue StandardError => e
    Rails.logger.error "Failed to update avatar for contact #{contact.id}: #{e.message}"
  end

  def fetch_profile_picture_url(phone_number)
    jid = "#{phone_number}@s.whatsapp.net"
    response = get_profile_pic(jid)
    response&.dig('data', 'profilePictureUrl')
  end

  def find_or_create_participant_contact(participant, inbox)
    lid = extract_lid_from_participant(participant)
    phone = extract_phone_from_participant(participant)
    identifier = lid ? "#{lid}@lid" : nil
    source_id = lid || phone

    return nil if source_id.blank?

    Whatsapp::ContactInboxConsolidationService.new(
      inbox: inbox, phone: phone, lid: lid, identifier: identifier
    ).perform

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: inbox,
      contact_attributes: {
        name: phone,
        phone_number: ("+#{phone}" if phone),
        identifier: identifier
      }
    ).perform

    return nil if contact_inbox.blank?

    update_participant_contact_info(contact_inbox.contact, phone, identifier)
  end

  def update_participant_contact_info(contact, phone, identifier)
    update_params = {
      phone_number: ("+#{phone}" if phone && contact.phone_number.blank?),
      identifier: (identifier if identifier && contact.identifier.blank?)
    }.compact

    contact.update!(update_params) if update_params.present?
    contact
  end

  def extract_lid_from_participant(participant)
    return nil if participant[:id].blank?

    jid_part, jid_suffix = participant[:id].split('@')
    jid_part if jid_suffix == 'lid' && jid_part.match?(/^\d+$/)
  end

  def extract_phone_from_participant(participant)
    return nil if participant[:phoneNumber].blank?

    phone = participant[:phoneNumber].split('@').first
    phone if phone.match?(/^\d+$/)
  end

  private_class_method def self.with_error_handling(*method_names)
    method_names.each do |method_name|
      original_method = instance_method(method_name)

      define_method("#{method_name}_without_error_handling") do |*args, **kwargs, &block|
        original_method.bind_call(self, *args, **kwargs, &block)
      end

      define_method(method_name) do |*args, **kwargs, &block|
        original_method.bind_call(self, *args, **kwargs, &block)
      rescue StandardError => e
        handle_channel_error
        raise e
      end
    end
  end

  def handle_channel_error
    whatsapp_channel.update_provider_connection!(connection: 'close')

    return if @handling_error

    @handling_error = true
    begin
      setup_channel_provider_without_error_handling
    rescue StandardError => e
      Rails.logger.error "Failed to reconnect channel after error: #{e.message}"
    ensure
      @handling_error = false
    end
  end

  with_error_handling :setup_channel_provider,
                      :disconnect_channel_provider,
                      :send_message,
                      :toggle_typing_status,
                      :update_presence,
                      :read_messages,
                      :unread_message,
                      :received_messages,
                      :group_metadata,
                      :sync_group,
                      :on_whatsapp,
                      :delete_message,
                      :edit_message,
                      :group_leave,
                      :group_setting_update,
                      :group_join_approval_mode,
                      :group_member_add_mode
end
