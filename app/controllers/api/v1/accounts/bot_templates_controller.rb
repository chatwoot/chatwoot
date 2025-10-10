class Api::V1::Accounts::BotTemplatesController < Api::V1::Accounts::BaseController
  # This controller provides bot-friendly API endpoints for template search, rendering, and sending
  # Supports authentication via API access tokens (user or agent bot tokens)

  before_action :validate_bot_access, only: [:search, :render, :send_message]

  # GET /api/v1/accounts/:account_id/bot_templates/search
  # Search templates by category, channel, tags, use_cases
  # Query params: category, channel, tags, use_cases, page, per_page
  def search
    templates = MessageTemplate
                .where(account: Current.account, status: 'active')
                .order(created_at: :desc)

    # Apply filters
    templates = templates.where(category: params[:category]) if params[:category].present?
    templates = templates.where('? = ANY(supported_channels)', params[:channel]) if params[:channel].present?

    if params[:tags].present?
      tags_array = params[:tags].is_a?(Array) ? params[:tags] : params[:tags].split(',')
      templates = templates.where('tags @> ARRAY[?]::varchar[]', tags_array)
    end

    if params[:use_cases].present?
      use_cases_array = params[:use_cases].is_a?(Array) ? params[:use_cases] : params[:use_cases].split(',')
      templates = templates.where('use_cases @> ARRAY[?]::varchar[]', use_cases_array)
    end

    # Pagination
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 20, 100].min # Max 100 per page

    paginated_templates = templates.offset((page - 1) * per_page).limit(per_page)

    render json: {
      templates: paginated_templates.map(&:bot_summary),
      total: templates.count,
      page: page,
      perPage: per_page,
      totalPages: (templates.count.to_f / per_page).ceil
    }
  rescue StandardError => e
    Rails.logger.error "[BotTemplates] Search failed: #{e.message}"
    render json: { error: 'Template search failed', details: e.message }, status: :internal_server_error
  end

  # POST /api/v1/accounts/:account_id/bot_templates/render
  # Render a template with parameters for a specific channel
  # Body: { template_id, parameters, channel_type, conversation_id (optional) }
  def render
    template = MessageTemplate.find_by(id: params[:template_id], account: Current.account)
    return render json: { error: 'Template not found' }, status: :not_found unless template

    # Validate channel compatibility
    channel_type = params[:channel_type]
    unless template.supported_channels.include?(channel_type)
      return render json: {
        error: 'Channel not supported',
        supportedChannels: template.supported_channels
      }, status: :unprocessable_entity
    end

    # Render the template
    service = Templates::BotRendererService.new(
      template_id: params[:template_id],
      parameters: params[:parameters] || {},
      channel_type: channel_type
    )

    result = service.render_for_bot

    # Log template usage
    log_template_usage(
      template: template,
      parameters: params[:parameters] || {},
      channel_type: channel_type,
      conversation_id: params[:conversation_id],
      success: true
    )

    render json: result
  rescue Templates::BotRendererService::ParameterValidationError => e
    render json: { error: 'Parameter validation failed', details: e.message }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error "[BotTemplates] Render failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Log failed attempt
    log_template_usage(
      template: template,
      parameters: params[:parameters] || {},
      channel_type: params[:channel_type],
      conversation_id: params[:conversation_id],
      success: false,
      error: e.message
    ) if template

    render json: { error: 'Template rendering failed', details: e.message }, status: :internal_server_error
  end

  # POST /api/v1/accounts/:account_id/bot_templates/send_message
  # Send a rendered template message to a conversation
  # Body: { conversation_id, template_id, parameters }
  def send_message
    conversation = Current.account.conversations.find_by(id: params[:conversation_id])
    return render json: { error: 'Conversation not found' }, status: :not_found unless conversation

    template = MessageTemplate.find_by(id: params[:template_id], account: Current.account)
    return render json: { error: 'Template not found' }, status: :not_found unless template

    # Determine sender (current user or bot)
    sender = determine_sender

    # Send template message
    service = Templates::BotMessagingService.new(
      conversation: conversation,
      template: template,
      parameters: params[:parameters] || {},
      sender: sender
    )

    message = service.send_template_message

    # Log template usage
    log_template_usage(
      template: template,
      parameters: params[:parameters] || {},
      channel_type: conversation.inbox.channel_type,
      conversation_id: conversation.id,
      success: true
    )

    render json: {
      message: message.push_event_data,
      templateApplied: true,
      templateId: template.id
    }
  rescue Templates::BotMessagingService::SendError => e
    render json: { error: 'Failed to send template message', details: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "[BotTemplates] Send message failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: 'Failed to send template message', details: e.message }, status: :internal_server_error
  end

  private

  def validate_bot_access
    # This endpoint is accessible by both users and bots via API tokens
    # Authentication is already handled by Api::BaseController
    # Just ensure we have a valid current user or bot
    return if Current.user.present?

    render json: { error: 'Authentication required' }, status: :unauthorized
  end

  def determine_sender
    # If authenticated as a bot, use the bot as sender
    # Otherwise use the current user
    if @resource.is_a?(AgentBot)
      @resource
    elsif Current.user.present?
      Current.account_user
    else
      # Fallback: find or create a default bot for this account
      AgentBot.where(account: Current.account, name: 'Template Bot').first_or_create!(
        description: 'Automated template message bot',
        bot_type: 'webhook'
      )
    end
  end

  def log_template_usage(template:, parameters:, channel_type:, conversation_id:, success:, error: nil)
    sender_type = if @resource.is_a?(AgentBot)
                    'AgentBot'
                  elsif Current.user.present?
                    'User'
                  else
                    'ExternalBot'
                  end

    sender_id = @resource&.id

    TemplateUsageLog.create!(
      message_template_id: template.id,
      account_id: Current.account.id,
      conversation_id: conversation_id,
      sender_type: sender_type,
      sender_id: sender_id,
      parameters_used: parameters,
      channel_type: channel_type,
      success: success,
      error_message: error
    )
  rescue StandardError => e
    Rails.logger.error "[BotTemplates] Failed to log template usage: #{e.message}"
    # Don't fail the request if logging fails
  end
end
