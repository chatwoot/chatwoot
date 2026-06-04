class Api::V1::Accounts::Conversations::GroupContactsController < Api::V1::Accounts::Conversations::BaseController
  RESULTS_PER_PAGE = 25
  PARTICIPANT_IDENTIFIER_KEYS = [:wa_id, :phone_number, :phoneNumber, :pn, :jid, :id, :user_id, :lid].freeze
  PARTICIPANT_PAYLOAD_KEYS = [:wa_id, :user_id].freeze
  before_action :ensure_session_group_admin, only: [:create, :destroy]

  def index
    @group_contacts = searchable_group_contacts.includes(:contact).page(params[:page]).per(RESULTS_PER_PAGE)
  end

  def create
    participants = participant_payloads(params[:participants])
    return render json: { error: 'participants are required' }, status: :unprocessable_entity if participants.blank?

    response = @conversation.inbox.channel.provider_service.add_group_participants(
      group_id: @conversation.group_source_id,
      participants: participants
    )
    return render json: response.parsed_response if response.success?

    Rails.logger.warn(
      "[WHATSAPP][GROUP] add participants failed conversation_id=#{@conversation.id} group_source_id=#{@conversation.group_source_id} " \
      "participants=#{participants.inspect} status=#{response.code} response=#{response.parsed_response.inspect}"
    )
    render json: { error: provider_error(response, 'Provider failed to add participants') }, status: :unprocessable_entity
  end

  def destroy
    participants = participant_identifiers(params[:participants])
    return head :no_content if participants.blank?

    response = remove_provider_participants(participants)
    unless provider_remove_success?(response)
      return render json: { error: provider_error(response, 'Provider failed to remove participants') }, status: :unprocessable_entity
    end

    @conversation.group_contacts.includes(contact: :contact_inboxes).find_each do |group_contact|
      group_contact.destroy! if participants.include?(participant_identifier(group_contact))
    end

    head :no_content
  end

  private

  def ensure_session_group_admin
    render json: { error: 'Connected session must be a group admin' }, status: :forbidden unless @conversation.group_session_admin?
  end

  def searchable_group_contacts
    scope = @conversation.group_contacts.joins(:contact)
    query = params[:query].to_s.strip
    return scope if query.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query.downcase)}%"
    scope.where(
      'LOWER(contacts.name) LIKE :pattern OR LOWER(contacts.whatsapp_username) LIKE :pattern OR ' \
      'LOWER(contacts.bsuid) LIKE :pattern OR LOWER(contacts.phone_number) LIKE :pattern OR ' \
      'LOWER(contacts.email) LIKE :pattern OR LOWER(group_contacts.metadata::text) LIKE :pattern',
      pattern: pattern
    )
  end

  def remove_provider_participants(participants)
    return unless @conversation.inbox.channel.provider == 'unoapi'

    @conversation.inbox.channel.provider_service.remove_group_participants(
      group_id: @conversation.group_source_id,
      participants: participants
    )
  end

  def provider_remove_success?(response)
    return true if response.blank?
    return false unless response.success?

    Array(response.parsed_response.try(:[], 'failed')).blank?
  end

  def participant_identifiers(raw_participants)
    Array(raw_participants).filter_map do |participant|
      participant_identifier_from_param(participant)
    end.uniq
  end

  def participant_payloads(raw_participants)
    Array(raw_participants).filter_map do |participant|
      participant_payload_from_param(participant)
    end.uniq
  end

  def participant_payload_from_param(participant)
    return participant.to_s.presence unless participant.respond_to?(:to_unsafe_h) || participant.is_a?(Hash)

    attrs = participant.respond_to?(:to_unsafe_h) ? participant.to_unsafe_h : participant
    attrs = attrs.with_indifferent_access
    wa_id = participant_phone_identifier(attrs)
    user_id = participant_lid_identifier(attrs)
    payload = PARTICIPANT_PAYLOAD_KEYS.each_with_object({}) do |key, result|
      value = key == :wa_id ? wa_id : user_id
      result[key.to_s] = value if value.present?
    end

    payload.presence
  end

  def participant_phone_identifier(attrs)
    [attrs[:wa_id], attrs[:phone_number], attrs[:phoneNumber], attrs[:pn], attrs[:jid], attrs[:id]].filter_map do |value|
      next if value.to_s.strip.end_with?('@lid')

      digits = value.to_s.gsub(/\D/, '')
      digits if digits.length >= 8
    end.first
  end

  def participant_lid_identifier(attrs)
    [attrs[:user_id], attrs[:lid], attrs[:wa_id], attrs[:jid], attrs[:id]].filter_map do |value|
      value = value.to_s.strip
      value if value.end_with?('@lid')
    end.first
  end

  def participant_identifier_from_param(participant)
    return participant.to_s.presence unless participant.respond_to?(:to_unsafe_h) || participant.is_a?(Hash)

    attrs = participant.respond_to?(:to_unsafe_h) ? participant.to_unsafe_h : participant
    attrs = attrs.with_indifferent_access
    PARTICIPANT_IDENTIFIER_KEYS.filter_map { |key| attrs[key].presence }.first
  end

  def provider_error(response, fallback)
    response.parsed_response.try(:[], 'error') || fallback
  end

  def participant_identifier(group_contact)
    metadata = group_contact.metadata || {}
    metadata_identifier = PARTICIPANT_IDENTIFIER_KEYS.filter_map { |key| metadata[key.to_s].presence }.first
    contact_inbox_source_id = group_contact.contact.contact_inboxes.find do |contact_inbox|
      contact_inbox.inbox_id == @conversation.inbox_id
    end&.source_id

    [metadata_identifier, contact_inbox_source_id, group_contact.contact.phone_number, group_contact.contact.bsuid,
     group_contact.contact.email].find(&:present?)
  end
  helper_method :participant_identifier
end
