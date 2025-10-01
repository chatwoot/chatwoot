class Api::V1::Accounts::Contacts::CallsController < Api::V1::Accounts::BaseController
  before_action :fetch_contact

  def create
    # Validate that contact has a phone number
    if @contact.phone_number.blank?
      render json: { error: 'Contact has no phone number' }, status: :unprocessable_entity
      return
    end

    # Use the outgoing call service to handle the entire process
    service = Voice::OutgoingCallService.new(
      account: Current.account,
      contact: @contact,
      user: Current.user,
      inbox_id: params[:inbox_id]
    )

    result = service.process
    conversation = Current.account.conversations.find_by!(display_id: result[:conversation_id])
    conference_sid = result[:conference_sid]
    call_sid = result[:call_sid]

    render json: {
      status: 'success',
      conversation_id: result[:conversation_id],
      inbox_id: conversation.inbox_id,
      conference_sid: conference_sid,
      call_sid: call_sid
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: 'not_found', code: 'not_found', details: e.message }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("VOICE_CONTACT_CALL_ERROR #{e.class}: #{e.message}")
    Sentry.capture_exception(e) if defined?(Sentry)
    Raven.capture_exception(e) if defined?(Raven)
    render json: { error: 'failed_to_initiate_call', code: 'initiate_error', details: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_contact
    @contact = Current.account.contacts.find(params[:contact_id])
  end
end
