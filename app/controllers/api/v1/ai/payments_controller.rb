class Api::V1::Ai::PaymentsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user, raise: false
  before_action :authenticate_ai_request

  # GET /api/v1/ai/payments/config
  # Check if payment gateways (Payzah and/or Tap) are configured for an account
  #
  # Parameters:
  #   - account_id: ID of the account to check configuration for
  #
  # Headers:
  #   - X-Api-Token: ALOOSTUDIO_API_TOKEN for authentication
  def config
    Rails.logger.info "[AI_PAYMENTS] 🔧 Config check request for account #{params[:account_id]}"

    account = Account.find_by(id: params[:account_id])

    unless account
      Rails.logger.error "[AI_PAYMENTS] Account #{params[:account_id]} not found"
      return render json: { error: 'Account not found' }, status: :not_found
    end

    payzah_configured = account.payzah_settings&.payzah_configured? || false
    tap_configured = account.tap_settings&.tap_configured? || false

    Rails.logger.info "[AI_PAYMENTS] ✅ Config check complete - Payzah: #{payzah_configured}, Tap: #{tap_configured}"

    render json: {
      success: true,
      account_id: account.id,
      providers: {
        payzah: {
          configured: payzah_configured,
          currencies: payzah_configured ? ['KWD'] : []
        },
        tap: {
          configured: tap_configured,
          currencies: tap_configured ? %w[KWD USD EUR GBP SAR AED BHD QAR OMR EGP JOD] : []
        }
      },
      any_configured: payzah_configured || tap_configured,
      default_provider: if tap_configured
                          'tap'
                        else
                          (payzah_configured ? 'payzah' : nil)
                        end
    }, status: :ok
  rescue StandardError => e
    Rails.logger.error "[AI_PAYMENTS] Error checking config: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: 'Internal server error', details: e.message }, status: :internal_server_error
  end

  # POST /api/v1/ai/payments/create_link
  # Generate a payment link for a conversation
  #
  # Parameters:
  #   - conversation_id: ID of the conversation to create payment link for (required)
  #   - amount: Payment amount (required)
  #   - currency: Currency code (optional, defaults to KWD)
  #   - provider: Payment provider - 'payzah' or 'tap' (optional, auto-detected if not provided)
  #
  # Headers:
  #   - X-Api-Token: ALOOSTUDIO_API_TOKEN for authentication
  def create_link
    Rails.logger.info '[AI_PAYMENTS] ========================================'
    Rails.logger.info '[AI_PAYMENTS] 💳 Payment link creation request received'
    Rails.logger.info "[AI_PAYMENTS] 📥 conversation_id: #{params[:conversation_id]}"
    Rails.logger.info "[AI_PAYMENTS] 📥 amount: #{params[:amount]}"
    Rails.logger.info "[AI_PAYMENTS] 📥 currency: #{params[:currency]}"
    Rails.logger.info "[AI_PAYMENTS] 📥 provider: #{params[:provider]}"

    # Validate required parameters
    return render json: { error: 'conversation_id is required' }, status: :bad_request unless params[:conversation_id].present?

    unless params[:amount].present? && params[:amount].to_f > 0
      return render json: { error: 'amount is required and must be positive' }, status: :bad_request
    end

    # Find conversation by ID or display_id
    conversation_id_param = params[:conversation_id].to_i
    conversation = Conversation.find_by(id: conversation_id_param)
    conversation ||= Conversation.find_by(display_id: conversation_id_param)

    unless conversation
      Rails.logger.error "[AI_PAYMENTS] Conversation not found: #{params[:conversation_id]}"
      return render json: { error: 'Conversation not found' }, status: :not_found
    end

    Rails.logger.info "[AI_PAYMENTS] ✅ Found conversation #{conversation.id} (display_id: #{conversation.display_id})"

    # Get AI agent (assignee) for the conversation
    ai_agent = conversation.assignee
    unless ai_agent&.is_ai?
      Rails.logger.error "[AI_PAYMENTS] Conversation #{conversation.id} is not assigned to an AI agent"
      return render json: { error: 'Conversation must be assigned to an AI agent' }, status: :bad_request
    end

    # Set Current.user to the AI agent for activity tracking
    Current.user = ai_agent

    # Create payment link using existing service
    payment_link = PaymentLinks::CreateService.new(
      conversation: conversation,
      user: ai_agent,
      amount: params[:amount].to_f,
      currency: params[:currency] || 'KWD',
      provider: params[:provider]
    ).perform

    Rails.logger.info '[AI_PAYMENTS] ========================================'
    Rails.logger.info "[AI_PAYMENTS] ✅ SUCCESS - Payment link created: #{payment_link.id}"
    Rails.logger.info "[AI_PAYMENTS]    - Payment URL: #{payment_link.payment_url}"
    Rails.logger.info "[AI_PAYMENTS]    - External ID: #{payment_link.external_payment_id}"
    Rails.logger.info "[AI_PAYMENTS]    - Provider: #{payment_link.provider}"
    Rails.logger.info '[AI_PAYMENTS] ========================================'

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
    Rails.logger.error "[AI_PAYMENTS] Validation error: #{e.message}"
    render json: { error: e.message }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error '[AI_PAYMENTS] ========================================'
    Rails.logger.error "[AI_PAYMENTS] ERROR - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    Rails.logger.error '[AI_PAYMENTS] ========================================'
    render json: { error: 'Internal server error', details: e.message }, status: :internal_server_error
  end

  # GET /api/v1/ai/payments/status
  # Check the status of a payment link
  #
  # Parameters:
  #   - payment_link_id: ID of the payment link (optional, use this OR external_payment_id)
  #   - external_payment_id: External payment ID/track ID (optional, use this OR payment_link_id)
  #
  # Headers:
  #   - X-Api-Token: ALOOSTUDIO_API_TOKEN for authentication
  def status
    Rails.logger.info "[AI_PAYMENTS] 📊 Status check request - payment_link_id: #{params[:payment_link_id]}, external_payment_id: #{params[:external_payment_id]}"

    payment_link = if params[:payment_link_id].present?
                     PaymentLink.find_by(id: params[:payment_link_id])
                   elsif params[:external_payment_id].present?
                     PaymentLink.find_by(external_payment_id: params[:external_payment_id])
                   end

    unless payment_link
      Rails.logger.error '[AI_PAYMENTS] Payment link not found'
      return render json: { error: 'Payment link not found' }, status: :not_found
    end

    Rails.logger.info "[AI_PAYMENTS] ✅ Found payment link #{payment_link.id} - Status: #{payment_link.status}"

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
    Rails.logger.error "[AI_PAYMENTS] Error checking status: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: 'Internal server error', details: e.message }, status: :internal_server_error
  end

  private

  def authenticate_ai_request
    api_token = request.headers['X-Api-Token']
    expected_token = ENV.fetch('ALOOSTUDIO_API_TOKEN', nil)

    Rails.logger.info "[AI_PAYMENTS] 🔐 Authenticating AI request with token: #{api_token&.truncate(20)}"

    if expected_token.blank?
      Rails.logger.error '[AI_PAYMENTS] ALOOSTUDIO_API_TOKEN not configured'
      render json: { error: 'API token not configured' }, status: :internal_server_error
      return
    end

    return if api_token == expected_token

    Rails.logger.error '[AI_PAYMENTS] Invalid API token provided'
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
