# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageWhatsappCloudService < Whatsapp::IncomingMessageBaseService
  GROUP_PARTICIPANTS_SYNC_INTERVAL = 2.hours

  def perform
    return process_group_settings_update if group_settings_update_event?

    super
  end

  private

  def group_settings_update_event?
    params.dig(:entry, 0, :changes, 0, :field).to_s == 'group_settings_update'
  end

  def process_group_settings_update
    value = params.dig(:entry, 0, :changes, 0, :value).to_h.with_indifferent_access
    group_id = value[:group_id].presence
    return if group_id.blank?

    conversation = inbox.conversations.find_by(group: true, group_source_id: group_id)
    return if conversation.blank?

    changes = value.fetch(:changes, {}).with_indifferent_access
    attrs = group_settings_attributes(changes)
    picture_url = group_settings_picture_url(changes)
    return if attrs.blank? && picture_url.blank?

    if picture_url.present?
      conversation.additional_attributes ||= {}
      conversation.additional_attributes['group_picture'] = picture_url
      Avatar::AvatarFromUrlJob.perform_later(conversation.contact, picture_url)
    end

    conversation.update!(attrs)
    conversation.contact.update!(name: attrs[:group_title]) if attrs[:group_title].present?
  end

  def group_settings_attributes(changes)
    attrs = {}
    attrs[:group_title] = changes[:subject].presence if changes.key?(:subject)
    attrs[:group_description] = changes[:description].presence if changes.key?(:description)
    attrs.compact
  end

  def group_settings_picture_url(changes)
    changes[:picture].presence || changes[:picture_url].presence || changes[:group_picture].presence
  end

  def set_contact
    return if contact_params.blank?

    return set_structured_group_contact if structured_group_message?

    super

    return unless group_message?

    @sender = outgoing_message_type? ? nil : @contact

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: group_payload[:group_source_id],
      inbox: inbox,
      contact_attributes: {
        email: group_payload[:group_source_id],
        name: group_payload[:group_title],
        avatar_url: group_payload[:group_picture].presence
      }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def processed_params
    @processed_params ||= params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
  end

  def download_attachment_file(attachment_payload)
    url_response = HTTParty.get(
      inbox.channel.media_url(attachment_payload[:id]),
      headers: inbox.channel.api_headers
    )
    # This url response will be failure if the access token has expired.
    inbox.channel.authorization_error! if url_response.unauthorized?
    Down.download(url_response.parsed_response['url'], headers: inbox.channel.api_headers) if url_response.success?
  end

  def message_content(message)
    content = super(message)
    return content if structured_group_message?

    group_message? && !outgoing_message_type? && @sender ? "*#{@sender.name}*: #{content}" : content
  end

  def group_message?
    group_payload[:group] || (contact_params.present? && contact_params[:group_id].present?)
  end

  def structured_group_message?
    return false unless inbox.channel.provider == 'unoapi'
    return false unless ActiveModel::Type::Boolean.new.cast(inbox.channel.provider_config['use_group_conversation_schema'])

    group_payload[:group]
  end

  def set_conversation
    return super unless structured_group_message?

    @conversation = Conversation.find_or_initialize_by(
      inbox_id: inbox.id,
      group_source_id: group_payload[:group_source_id]
    )
    @conversation.assign_attributes(
      account_id: inbox.account_id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      group: true,
      group_title: group_payload[:group_title].presence || group_payload[:group_source_id],
      additional_attributes: group_additional_attributes
    )
    @conversation.save!

    sync_group_sender_contact
  end

  def process_statuses
    status = @processed_params[:statuses].first
    return process_group_status(status) if status[:recipient_type].to_s == 'group'

    super
  end

  def contact_params
    @contact_params ||= @processed_params[:contacts]&.first
  end

  def group_payload
    @group_payload ||= Whatsapp::GroupPayloadNormalizer.new(processed_params: @processed_params, inbox: inbox).perform
  end

  def lid_message?
    contact_params.present? && contact_params[:wa_id]&.include?('@lid')
  end

  def set_message_type
    @message_type = :activity
    return if activity_message_type?

    @message_type = outgoing_message_type? ? :outgoing : :incoming
  end

  def outgoing_message_type?
    message = @processed_params[:messages]&.first
    return if message.blank?

    display_phone_number = @processed_params.dig(:metadata, :display_phone_number)
    return false if display_phone_number.blank?

    message[:from] == display_phone_number.sub('+', '')
  end

  def activity_message_type?
    message = @processed_params[:messages]&.first
    return if message.blank?

    return if contact_params.blank?

    display_phone_number = @processed_params.dig(:metadata, :display_phone_number)
    return if display_phone_number.blank?

    !group_message? &&
      display_phone_number.sub('+', '') == contact_params[:wa_id] && contact_params[:wa_id] == message[:from]
  end

  def set_structured_group_contact
    Rails.logger.info("[WHATSAPP][GROUP] structured inbound group_source_id=#{group_payload[:group_source_id]}")

    merge_structured_group_sender_contact

    sender_contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: structured_sender_source_id,
      inbox: inbox,
      contact_attributes: structured_sender_contact_attributes
    ).perform
    @sender = webhook_outgoing_message? ? nil : sender_contact_inbox.contact

    group_contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: group_payload[:group_source_id],
      inbox: inbox,
      contact_attributes: {
        email: group_payload[:group_source_id],
        name: group_payload[:group_title],
        avatar_url: group_payload[:group_picture].presence
      }
    ).perform

    @contact_inbox = group_contact_inbox
    @contact = group_contact_inbox.contact
  end

  def structured_sender_source_id
    group_payload[:sender_identifier].to_s
  end

  def structured_sender_contact_attributes
    attrs = {
      name: group_payload[:sender_name],
      avatar_url: group_payload[:sender_picture].presence,
      bsuid: group_payload[:sender_bsuid],
      whatsapp_username: group_payload[:sender_username]
    }.compact

    phone = group_payload[:sender_phone].to_s.gsub(/\D/, '')
    normalized_phone = brazil_phone_number?(phone) ? normalised_brazil_mobile_number(phone) : phone
    attrs[:phone_number] = "+#{normalized_phone}" if normalized_phone.present?
    attrs
  end

  def merge_structured_group_sender_contact
    Whatsapp::Unoapi::GroupParticipantContactMerger.new(account: inbox.account, inbox: inbox).perform_from_group_payload(group_payload)
  end

  def group_additional_attributes
    attrs = @conversation.additional_attributes || {}
    return attrs if group_payload[:group_picture].blank?

    attrs.merge('group_picture' => group_payload[:group_picture])
  end

  def sync_group_sender_contact
    return if @sender.blank?

    @conversation.group_contacts.find_or_create_by!(contact: @sender) do |group_contact|
      group_contact.account_id = @conversation.account_id
      group_contact.metadata = {
        jid: group_payload[:sender_identifier],
        wa_id: group_payload[:sender_phone],
        user_id: group_payload[:sender_bsuid],
        username: group_payload[:sender_username],
        picture: group_payload[:sender_picture]
      }.compact
    end

    enqueue_group_participants_sync
  end

  def enqueue_group_participants_sync
    return unless group_participants_sync_due?

    Whatsapp::Unoapi::GroupParticipantsSyncJob.perform_later(@conversation.id)
    Rails.logger.info(
      "[WHATSAPP][GROUP] participants sync enqueued conversation_id=#{@conversation.id} group_source_id=#{@conversation.group_source_id}"
    )
  end

  def group_participants_sync_due?
    @conversation.group_contacts_synced_at.blank? ||
      @conversation.group_contacts_synced_at <= GROUP_PARTICIPANTS_SYNC_INTERVAL.ago
  end

  def process_group_status(status)
    Rails.logger.info("[WHATSAPP][GROUP] status received recipient_id=#{status[:recipient_id]} status=#{status[:status]}")
    conversation = inbox.conversations.find_by(group: true, group_source_id: status[:recipient_id])
    return if conversation.blank?

    message = conversation.messages.find_by(source_id: status[:id])
    return if message.blank?

    update_message_with_status(message, status)
  end
end
