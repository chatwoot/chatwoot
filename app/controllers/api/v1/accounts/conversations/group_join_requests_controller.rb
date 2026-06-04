class Api::V1::Accounts::Conversations::GroupJoinRequestsController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_group_conversation
  before_action :ensure_session_group_admin

  def index
    response = provider_service.group_join_requests(@conversation.group_source_id)
    return render json: normalized_join_requests(response.parsed_response) if response.success?

    render json: { error: provider_error(response, 'Provider failed to fetch join requests') }, status: :unprocessable_entity
  end

  def create
    response = provider_service.approve_group_join_requests(
      group_id: @conversation.group_source_id,
      participants: participants
    )
    return render json: response.parsed_response if response.success?

    render json: { error: provider_error(response, 'Provider failed to approve join requests') }, status: :unprocessable_entity
  end

  def destroy
    response = provider_service.reject_group_join_requests(
      group_id: @conversation.group_source_id,
      participants: participants
    )
    return render json: response.parsed_response if response.success?

    render json: { error: provider_error(response, 'Provider failed to reject join requests') }, status: :unprocessable_entity
  end

  private

  def provider_service
    @provider_service ||= @conversation.inbox.channel.provider_service
  end

  def participants
    Array(params[:participants]).filter_map do |participant|
      participant_identifier(participant)
    end.uniq
  end

  def participant_identifier(participant)
    return participant.to_s.presence unless participant.respond_to?(:to_unsafe_h) || participant.is_a?(Hash)

    attrs = participant.respond_to?(:to_unsafe_h) ? participant.to_unsafe_h : participant
    attrs = attrs.with_indifferent_access
    attrs[:wa_id].presence || attrs[:phone_number].presence || attrs[:phoneNumber].presence || attrs[:pn].presence ||
      attrs[:jid].presence || attrs[:id].presence || attrs[:user_id].presence || attrs[:lid].presence
  end

  def ensure_group_conversation
    render json: { error: 'Conversation is not a group' }, status: :not_found unless @conversation.group?
  end

  def ensure_session_group_admin
    render json: { error: 'Connected session must be a group admin' }, status: :forbidden unless @conversation.group_session_admin?
  end

  def provider_error(response, fallback)
    response.parsed_response.try(:[], 'error') || fallback
  end

  def normalized_join_requests(payload)
    payload = payload.with_indifferent_access if payload.respond_to?(:with_indifferent_access)
    requests = join_requests_from(payload)

    {
      join_requests: requests,
      count: join_requests_count(payload, requests)
    }
  end

  def join_requests_from(payload)
    return payload if payload.is_a?(Array)
    return [] unless payload.respond_to?(:[])

    Array(payload[:join_requests].presence || payload[:requests].presence || payload[:participants].presence || payload[:data].presence)
  end

  def join_requests_count(payload, requests)
    return requests.length unless payload.respond_to?(:[])

    payload[:count].presence || payload[:pending_count].presence || payload[:total].presence || requests.length
  end
end
