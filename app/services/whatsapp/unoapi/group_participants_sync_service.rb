# rubocop:disable Metrics/ClassLength
class Whatsapp::Unoapi::GroupParticipantsSyncService
  def initialize(inbox:, conversation:, group_source_id: nil)
    @inbox = inbox
    @channel = inbox.channel
    @conversation = conversation
    @group_source_id = group_source_id.presence || conversation.group_source_id
  end

  def perform
    return :missing_group unless @conversation.group? && @group_source_id.present?
    return :unsupported_provider unless @channel.respond_to?(:provider_service) && @channel.provider == 'unoapi'

    response = @channel.provider_service.group_participants(@group_source_id)
    return cache_miss if response.code.to_i == 404

    unless response.success?
      Rails.logger.error("[WHATSAPP][GROUP] participants sync failed group_source_id=#{@group_source_id} status=#{response.code}")
      return :failed
    end

    sync_payload(enriched_payload(response.parsed_response.with_indifferent_access))
    :ok
  end

  private

  def cache_miss
    Rails.logger.info("[WHATSAPP][GROUP] participants sync cache_miss group_source_id=#{@group_source_id}")
    :cache_miss
  end

  def enriched_payload(payload)
    group = (payload[:group] || {}).with_indifferent_access
    group.merge!(group_details_payload)
    invite_link = group_invite_link
    group[:invite_link] = invite_link if invite_link.present?
    payload[:group] = group
    payload
  end

  def group_details_payload
    response = provider_response(:group_details)
    return {} unless response&.success?

    details = (response.parsed_response || {}).with_indifferent_access
    {
      subject: details[:subject].presence,
      description: details[:description].presence,
      picture: group_picture_url(details),
      join_approval_mode: details[:join_approval_mode].presence,
      created_at: details[:created_at].presence || details[:creation_timestamp].presence,
      suspended: details[:suspended]
    }.compact
  end

  def group_invite_link
    response = provider_response(:group_invite_link)
    return unless response&.success?

    (response.parsed_response || {}).with_indifferent_access[:invite_link].presence
  end

  def provider_response(method_name)
    return unless @channel.provider_service.respond_to?(method_name)

    @channel.provider_service.public_send(method_name, @group_source_id)
  rescue StandardError => e
    Rails.logger.warn("[WHATSAPP][GROUP] #{method_name} skipped group_source_id=#{@group_source_id} error=#{e.class}: #{e.message}")
    nil
  end

  def sync_payload(payload)
    participants = Array(payload[:participants]).map(&:with_indifferent_access)

    update_group_metadata(payload[:group] || {})
    synced_contact_ids = participants.filter_map { |participant| sync_participant(participant) }
    session_in_group = participants.any? { |participant| session_participant?(participant) }
    remove_stale_group_contacts(synced_contact_ids) if participants.present?
    sync_session_membership_activity(session_in_group) if participants.present?
    @conversation.group_session_admin = session_admin?(participants)
    @conversation.update!(group_contacts_synced_at: Time.current)
  end

  def update_group_metadata(group)
    attrs = {
      group_title: group[:subject].presence,
      group_description: group[:description].presence,
      group_invite_link: group[:invite_link].presence,
      group_join_approval_mode: group[:join_approval_mode].presence,
      group_created_at_external: external_time(group[:created_at].presence || group[:creation_timestamp].presence)
    }.compact
    attrs[:group_suspended] = group[:suspended] unless group[:suspended].nil?

    picture_url = group_picture_url(group)
    if picture_url.present?
      @conversation.additional_attributes ||= {}
      @conversation.additional_attributes['group_picture'] = picture_url
      Avatar::AvatarFromUrlJob.perform_later(@conversation.contact, picture_url)
    end

    @conversation.assign_attributes(attrs)
    @conversation.save! if @conversation.changed?
  end

  def sync_participant(participant)
    source_id = participant_source_id(participant)
    return if source_id.blank?

    Whatsapp::Unoapi::GroupParticipantContactMerger.new(account: @conversation.account, inbox: @inbox, conversation: @conversation).perform(
      participant: participant,
      source_id: source_id
    )
    sanitize_existing_contact_email(source_id, participant)

    contact_inbox = ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: @inbox,
      contact_attributes: contact_attributes(participant, source_id)
    ).perform

    group_contact = @conversation.group_contacts.find_or_initialize_by(contact: contact_inbox.contact)
    group_contact.account_id = @conversation.account_id
    group_contact.metadata = participant_metadata(participant, source_id, group_contact.metadata || {})
    group_contact.save!
    group_contact.contact_id
  end

  def remove_stale_group_contacts(synced_contact_ids)
    @conversation.group_contacts.where.not(contact_id: synced_contact_ids).destroy_all
  end

  def sync_session_membership_activity(session_in_group)
    @conversation.additional_attributes ||= {}
    return clear_session_removed_marker if session_in_group
    return if @conversation.additional_attributes['group_session_removed_at'].present?

    @conversation.messages.create!(
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :activity,
      content: I18n.t('conversations.activity.whatsapp.group_session_removed')
    )
    @conversation.additional_attributes['group_session_removed_at'] = Time.current.iso8601
  end

  def clear_session_removed_marker
    @conversation.additional_attributes.delete('group_session_removed_at')
  end

  def sanitize_existing_contact_email(source_id, participant)
    contact = existing_participant_contact(source_id, participant)
    return if contact.blank? || contact.email.blank?

    sanitize_contact_email(contact)
  end

  def sanitize_contact_email(contact)
    return if contact.email.blank? || valid_contact_email?(contact.email)

    Rails.logger.info("[WHATSAPP][GROUP] clearing invalid participant email contact_id=#{contact.id} email=#{contact.email}")
    contact.update_columns(email: nil, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  def existing_participant_contact(source_id, participant)
    @inbox.contact_inboxes.find_by(source_id: source_id)&.contact ||
      Contact.find_by(account_id: @conversation.account_id, bsuid: participant_bsuid(participant))
  end

  def valid_contact_email?(email) = email.match?(Devise.email_regexp) || email.end_with?('@lid') || email.end_with?('@g.us')

  def contact_attributes(participant, source_id)
    attrs = {
      name: participant_name(participant, source_id),
      avatar_url: participant_picture_url(participant),
      bsuid: participant_bsuid(participant),
      whatsapp_username: participant[:username].presence
    }.compact

    unless source_id.include?('@')
      phone = normalized_phone((participant[:wa_id].presence || source_id).to_s.gsub(/\D/, ''))
      attrs[:phone_number] = "+#{phone}" if phone.present?
    end

    attrs
  end

  def participant_name(participant, source_id)
    participant[:name].presence ||
      participant[:pushname].presence ||
      participant[:username].presence ||
      participant[:wa_id].presence ||
      participant_bsuid(participant) ||
      source_id
  end

  def participant_metadata(participant, source_id, current_metadata = {})
    picture_url = participant_picture_url(participant).presence || current_metadata['picture'].presence

    {
      jid: participant[:jid].presence || source_id,
      wa_id: participant[:wa_id].presence,
      lid: participant[:lid].presence,
      user_id: participant[:user_id].presence,
      username: participant[:username].presence,
      role: participant[:role].presence,
      is_admin: participant[:is_admin],
      picture: picture_url
    }.compact
  end

  def group_picture_url(group)
    group[:picture].presence ||
      group[:profile_url].presence ||
      group[:profile_picture_url].presence ||
      group[:group_picture].presence ||
      group.dig(:profile, :picture).presence ||
      group.dig(:profile, :profile_url).presence
  end

  def participant_picture_url(participant)
    participant[:picture].presence ||
      participant[:profile_url].presence ||
      participant[:profile_picture_url].presence ||
      participant.dig(:profile, :picture).presence ||
      participant.dig(:profile, :profile_url).presence
  end

  def participant_source_id(participant)
    return participant[:wa_id] if participant[:wa_id].present?
    return participant_bsuid(participant) if participant_bsuid(participant).present?
    return participant[:jid] if participant[:jid].to_s.include?('@lid')

    participant[:jid].to_s.gsub(/\D/, '').presence
  end

  def participant_bsuid(participant) = participant[:user_id].presence || participant[:lid].presence

  def session_admin?(participants)
    session_participant = participants.find { |participant| session_participant?(participant) }
    return false if session_participant.blank?

    ActiveModel::Type::Boolean.new.cast(session_participant[:is_admin]) ||
      session_participant[:role].to_s.casecmp('admin').zero? ||
      session_participant[:role].to_s.casecmp('superadmin').zero?
  end

  def session_participant?(participant)
    identifiers = participant_identifiers(participant)

    session_identifiers.any? do |session_identifier|
      identifiers.any? { |identifier| identifier == session_identifier || identifier.gsub(/\D/, '') == session_identifier.gsub(/\D/, '') }
    end
  end

  def participant_identifiers(participant)
    identifiers = [
      participant[:wa_id],
      participant[:jid],
      participant[:lid],
      participant[:user_id],
      participant_source_id(participant)
    ].compact.map(&:to_s)

    participant_contact = participant_contact(participant, identifiers)
    identifiers.concat(contact_identifiers(participant_contact)) if participant_contact.present?
    identifiers.uniq
  end

  def participant_contact(participant, identifiers)
    @inbox.contact_inboxes.includes(:contact).find_by(source_id: identifiers)&.contact ||
      Contact.find_by(account_id: @conversation.account_id, bsuid: participant_bsuid(participant))
  end

  def contact_identifiers(contact)
    [contact.phone_number, contact.bsuid, *contact.contact_inboxes.where(inbox: @inbox).pluck(:source_id)].compact.map(&:to_s)
  end

  def session_identifiers
    @session_identifiers ||= [
      @channel.provider_config['business_account_id'],
      @channel.provider_config['phone_number_id'],
      @channel.phone_number
    ].compact.map(&:to_s).flat_map do |identifier|
      digits = identifier.gsub(/\D/, '')
      [identifier, digits, normalized_phone(digits)].compact
    end.uniq
  end

  def external_time(value)
    return if value.blank?
    return Time.zone.at(value.to_i) if value.to_s.match?(/\A\d+\z/)

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def normalized_phone(phone) = phone.start_with?('55') && phone.length == 12 ? "#{phone[0..3]}9#{phone[4..]}" : phone
end
# rubocop:enable Metrics/ClassLength
