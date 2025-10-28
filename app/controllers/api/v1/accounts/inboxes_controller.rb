class Api::V1::Accounts::InboxesController < Api::V1::Accounts::BaseController
  include Api::V1::InboxesHelper
  before_action :fetch_inbox, except: [:index, :create]
  before_action :fetch_agent_bot, only: [:set_agent_bot]
  before_action :validate_limit, only: [:create]
  # we are already handling the authorization in fetch inbox
  before_action :check_authorization, except: [:show, :health]
  before_action :validate_whatsapp_cloud_channel, only: [:health]

  def index
    @inboxes = policy_scope(Current.account.inboxes.order_by_name.includes(:channel, { avatar_attachment: [:blob] }))
  end

  def show; end

  # Deprecated: This API will be removed in 2.7.0
  def assignable_agents
    @assignable_agents = @inbox.assignable_agents
  end

  def campaigns
    @campaigns = @inbox.campaigns
  end

  def avatar
    @inbox.avatar.attachment.destroy! if @inbox.avatar.attached?
    head :ok
  end

  def create
    ActiveRecord::Base.transaction do
      channel = create_channel
      @inbox = Current.account.inboxes.build(
        {
          name: inbox_name(channel),
          channel: channel
        }.merge(
          permitted_params.except(:channel)
        )
      )
      @inbox.save!
    end
  end

  def update
    inbox_params = permitted_params.except(:channel, :csat_config)
    inbox_params[:csat_config] = format_csat_config(permitted_params[:csat_config]) if permitted_params[:csat_config].present?

    @inbox.update!(inbox_params)
    update_inbox_working_hours
    update_channel if channel_update_required?
  end

  def agent_bot
    @agent_bot = @inbox.agent_bot
  end

  def set_agent_bot
    if @agent_bot
      agent_bot_inbox = @inbox.agent_bot_inbox || AgentBotInbox.new(inbox: @inbox)
      agent_bot_inbox.agent_bot = @agent_bot
      agent_bot_inbox.save!
    elsif @inbox.agent_bot_inbox.present?
      @inbox.agent_bot_inbox.destroy!
    end
    head :ok
  end

  def destroy
    ::DeleteObjectJob.perform_later(@inbox, Current.user, request.ip) if @inbox.present?
    render status: :ok, json: { message: I18n.t('messages.inbox_deletetion_response') }
  end

  def sync_templates
    return render status: :unprocessable_entity, json: { error: 'Template sync is only available for WhatsApp channels' } unless whatsapp_channel?

    trigger_template_sync
    render status: :ok, json: { message: 'Template sync initiated successfully' }
  rescue StandardError => e
    render status: :internal_server_error, json: { error: e.message }
  end

  def health
    health_data = Whatsapp::HealthService.new(@inbox.channel).fetch_health_status
    render json: health_data
  rescue StandardError => e
    Rails.logger.error "[INBOX HEALTH] Error fetching health data: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def csat_template_status
    return render json: { error: 'CSAT template status only available for WhatsApp channels' }, status: :bad_request unless @inbox.whatsapp?

    template_config = @inbox.csat_config&.dig('template')
    return render json: { template_exists: false } unless template_config

    template_name = template_config['name'] || 'customer_satisfaction_survey'
    status_result = @inbox.channel.provider_service.get_template_status(template_name)

    if status_result[:success]
      render json: {
        template_exists: true,
        template_name: template_name,
        status: status_result[:template][:status],
        template_id: status_result[:template][:id]
      }
    else
      render json: { template_exists: false, error: status_result[:error] }
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching CSAT template status: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  def create_csat_template
    unless @inbox.whatsapp?
      return render json: { error: 'CSAT template creation only available for WhatsApp channels' },
                    status: :unprocessable_content
    end

    template_params = params.require(:template).permit(:message, :button_text)
    return render json: { error: 'Message is required' }, status: :unprocessable_content if template_params[:message].blank?

    template_config = {
      message: template_params[:message],
      button_text: template_params[:button_text] || 'Please rate us',
      base_url: ENV.fetch('FRONTEND_URL', 'http://localhost:3000'),
      language: 'en'
    }

    result = @inbox.channel.provider_service.create_csat_template(template_config)

    if result[:success]
      render json: {
        template: {
          name: 'customer_satisfaction_survey',
          template_id: result[:template_id],
          status: 'PENDING',
          language: 'en'
        }
      }, status: :created
    else
      # Parse WhatsApp error details for user-friendly message
      whatsapp_error = parse_whatsapp_error(result[:response_body])
      render json: {
        error: whatsapp_error[:user_message] || result[:error],
        details: whatsapp_error[:technical_details]
      }, status: :unprocessable_content
    end
  rescue ActionController::ParameterMissing
    render json: { error: 'Template parameters are required' }, status: :unprocessable_content
  rescue StandardError => e
    Rails.logger.error "Error creating CSAT template: #{e.message}"
    render json: { error: 'Template creation failed' }, status: :internal_server_error
  end

  private

  def parse_whatsapp_error(response_body)
    return { user_message: nil, technical_details: nil } if response_body.blank?

    begin
      error_data = JSON.parse(response_body)
      whatsapp_error = error_data['error'] || {}

      user_message = whatsapp_error['error_user_msg'] || whatsapp_error['message']
      technical_details = {
        code: whatsapp_error['code'],
        subcode: whatsapp_error['error_subcode'],
        type: whatsapp_error['type'],
        title: whatsapp_error['error_user_title']
      }.compact

      { user_message: user_message, technical_details: technical_details }
    rescue JSON::ParserError
      { user_message: nil, technical_details: response_body }
    end
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id])
    authorize @inbox, :show?
  end

  def fetch_agent_bot
    @agent_bot = AgentBot.find(params[:agent_bot]) if params[:agent_bot]
  end

  def validate_whatsapp_cloud_channel
    return if @inbox.channel.is_a?(Channel::Whatsapp) && @inbox.channel.provider == 'whatsapp_cloud'

    render json: { error: 'Health data only available for WhatsApp Cloud API channels' }, status: :bad_request
  end

  def create_channel
    return unless allowed_channel_types.include?(permitted_params[:channel][:type])

    account_channels_method.create!(permitted_params(channel_type_from_params::EDITABLE_ATTRS)[:channel].except(:type))
  end

  def allowed_channel_types
    %w[web_widget api email line telegram whatsapp sms]
  end

  def update_inbox_working_hours
    @inbox.update_working_hours(params.permit(working_hours: Inbox::OFFISABLE_ATTRS)[:working_hours]) if params[:working_hours]
  end

  def update_channel
    channel_attributes = get_channel_attributes(@inbox.channel_type)
    return if permitted_params(channel_attributes)[:channel].blank?

    validate_and_update_email_channel(channel_attributes) if @inbox.inbox_type == 'Email'

    reauthorize_and_update_channel(channel_attributes)
    update_channel_feature_flags
  end

  def channel_update_required?
    permitted_params(get_channel_attributes(@inbox.channel_type))[:channel].present?
  end

  def validate_and_update_email_channel(channel_attributes)
    validate_email_channel(channel_attributes)
  rescue StandardError => e
    render json: { message: e }, status: :unprocessable_entity and return
  end

  def reauthorize_and_update_channel(channel_attributes)
    @inbox.channel.reauthorized! if @inbox.channel.respond_to?(:reauthorized!)
    @inbox.channel.update!(permitted_params(channel_attributes)[:channel])
  end

  def update_channel_feature_flags
    return unless @inbox.web_widget?
    return unless permitted_params(Channel::WebWidget::EDITABLE_ATTRS)[:channel].key? :selected_feature_flags

    @inbox.channel.selected_feature_flags = permitted_params(Channel::WebWidget::EDITABLE_ATTRS)[:channel][:selected_feature_flags]
    @inbox.channel.save!
  end

  def format_csat_config(config)
    formatted = {
      'display_type' => config['display_type'] || 'emoji',
      'message' => config['message'] || '',
      'button_text' => config['button_text'] || 'Please rate us',
      'survey_rules' => {
        'operator' => config.dig('survey_rules', 'operator') || 'contains',
        'values' => config.dig('survey_rules', 'values') || []
      }
    }

    # Preserve existing template config if present
    formatted['template'] = config['template'] if config['template'].present?

    formatted
  end

  def inbox_attributes
    [:name, :avatar, :greeting_enabled, :greeting_message, :enable_email_collect, :csat_survey_enabled,
     :enable_auto_assignment, :working_hours_enabled, :out_of_office_message, :timezone, :allow_messages_after_resolved,
     :lock_to_single_conversation, :portal_id, :sender_name_type, :business_name,
     { csat_config: [:display_type, :message, :button_text,
                     { survey_rules: [:operator, { values: [] }],
                       template: [:name, :template_id, :created_at, :language] }] }]
  end

  def permitted_params(channel_attributes = [])
    # We will remove this line after fixing https://linear.app/chatwoot/issue/CW-1567/null-value-passed-as-null-string-to-backend
    params.each { |k, v| params[k] = params[k] == 'null' ? nil : v }

    params.permit(
      *inbox_attributes,
      channel: [:type, *channel_attributes]
    )
  end

  def channel_type_from_params
    {
      'web_widget' => Channel::WebWidget,
      'api' => Channel::Api,
      'email' => Channel::Email,
      'line' => Channel::Line,
      'telegram' => Channel::Telegram,
      'whatsapp' => Channel::Whatsapp,
      'sms' => Channel::Sms
    }[permitted_params[:channel][:type]]
  end

  def get_channel_attributes(channel_type)
    if channel_type.constantize.const_defined?(:EDITABLE_ATTRS)
      channel_type.constantize::EDITABLE_ATTRS.presence
    else
      []
    end
  end

  def whatsapp_channel?
    @inbox.whatsapp? || (@inbox.twilio? && @inbox.channel.whatsapp?)
  end

  def trigger_template_sync
    if @inbox.whatsapp?
      Channels::Whatsapp::TemplatesSyncJob.perform_later(@inbox.channel)
    elsif @inbox.twilio? && @inbox.channel.whatsapp?
      Channels::Twilio::TemplatesSyncJob.perform_later(@inbox.channel)
    end
  end
end

Api::V1::Accounts::InboxesController.prepend_mod_with('Api::V1::Accounts::InboxesController')
