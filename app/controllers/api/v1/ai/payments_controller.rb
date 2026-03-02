class Api::V1::Ai::PaymentsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user, raise: false
  before_action :authenticate_ai_request

  # GET /api/v1/ai/payments/config
  def check_config
    account = Account.find_by(id: params[:account_id])

    return render json: { error: 'Account not found' }, status: :not_found unless account

    payzah_configured = account.payzah_settings&.payzah_configured? || false
    tap_configured = account.tap_settings&.tap_configured? || false

    render json: {
      success: true,
      account_id: account.id,
      providers: {
        payzah: { configured: payzah_configured, currencies: payzah_configured ? ['KWD'] : [] },
        tap: { configured: tap_configured, currencies: tap_configured ? %w[KWD USD EUR GBP SAR AED BHD QAR OMR EGP JOD] : [] }
      },
      any_configured: payzah_configured || tap_configured,
      default_provider: if tap_configured
                          'tap'
                        else
                          (payzah_configured ? 'payzah' : nil)
                        end
    }, status: :ok
  rescue StandardError => e
    render json: { error: 'Internal server error', details: e.message }, status: :internal_server_error
  end

  # POST /api/v1/ai/payments/create_link
  def create_link
    return render json: { error: 'conversation_id is required' }, status: :bad_request unless params[:conversation_id].present?

    unless params[:amount].present? && params[:amount].to_f.positive?
      return render json: { error: 'amount is required and must be positive' }, status: :bad_request
    end

    conversation_id_param = params[:conversation_id].to_i
    conversation = Conversation.find_by(id: conversation_id_param) || Conversation.find_by(display_id: conversation_id_param)

    return render json: { error: 'Conversation not found' }, status: :not_found unless conversation

    ai_agent = conversation.assignee
    return render json: { error: 'Conversation must be assigned to an AI agent' }, status: :bad_request unless ai_agent&.is_ai?

    Current.user = ai_agent

    payment_link = PaymentLinks::CreateService.new(
      conversation: conversation,
      user: ai_agent,
      amount: params[:amount].to_f,
      currency: params[:currency] || 'KWD',
      provider: params[:provider]
    ).perform

    render json: {
      success: true,
      payment_link: {
        id: payment_link.id,
        external_payment_id: payment_link.external_payment_id,
        payment_url: payment_link.payment_url,
        amount: payment_link.amount.to_f,
        currency: payment_link.currency,
        provider: payment_link.provider,
        status: payment_link.status,
        created_at: payment_link.created_at.iso8601
      },
      conversation_id: conversation.id,
      conversation_display_id: conversation.display_id,
      message: 'Payment link created successfully'
    }, status: :created
  rescue ArgumentError => e
    render json: { error: e.message }, status: :bad_request
  rescue StandardError => e
    render json: { error: 'Internal server error', details: e.message }, status: :internal_server_error
  end

  # GET /api/v1/ai/payments/status
  def status
    payment_link = if params[:payment_link_id].present?
                     PaymentLink.find_by(id: params[:payment_link_id])
                   elsif params[:external_payment_id].present?
                     PaymentLink.find_by(external_payment_id: params[:external_payment_id])
                   end

    return render json: { error: 'Payment link not found' }, status: :not_found unless payment_link

    render json: {
      success: true,
      payment_link: {
        id: payment_link.id,
        external_payment_id: payment_link.external_payment_id,
        payment_url: payment_link.payment_url,
        amount: payment_link.amount.to_f,
        currency: payment_link.currency,
        provider: payment_link.provider,
        status: payment_link.status,
        is_paid: payment_link.paid?,
        is_pending: payment_link.pending?,
        is_failed: payment_link.failed?,
        is_expired: payment_link.expired?,
        is_cancelled: payment_link.cancelled?,
        paid_at: payment_link.paid_at&.iso8601,
        created_at: payment_link.created_at.iso8601,
        updated_at: payment_link.updated_at.iso8601
      },
      conversation_id: payment_link.conversation_id,
      conversation_display_id: payment_link.conversation.display_id,
      contact: {
        id: payment_link.contact_id,
        name: payment_link.contact.name,
        email: payment_link.contact.email,
        phone: payment_link.contact.phone_number
      }
    }, status: :ok
  rescue StandardError => e
    render json: { error: 'Internal server error', details: e.message }, status: :internal_server_error
  end

  private

  def authenticate_ai_request
    api_token = request.headers['X-Api-Token']
    expected_token = ENV.fetch('ALOOSTUDIO_API_TOKEN', nil)

    if expected_token.blank?
      render json: { error: 'API token not configured' }, status: :internal_server_error
      return
    end

    return if api_token == expected_token

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
