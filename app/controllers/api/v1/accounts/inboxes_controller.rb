class Api::V1::Accounts::InboxesController < Api::V1::Accounts::BaseController # rubocop:disable Metrics/ClassLength
  include WorkingHoursHelper
  include Api::V1::InboxesHelper
  before_action :fetch_inbox, except: [:index, :create]
  before_action :fetch_agent_bot, only: [:set_agent_bot]
  before_action :validate_limit, only: [:create]
  # we are already handling the authorization in fetch inbox
  before_action :check_authorization, except: [:show]

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

  def channel_avatar
    @inbox.channel.avatar.attachment.destroy! if @inbox.channel.respond_to?(:avatar) && @inbox.channel.avatar.attached?
    head :ok
  end

  def add_web_widget_inbox_multichannel # rubocop:disable Metrics/MethodLength
    shop_url = fetch_shop_url(@inbox.account.id)
    response = HTTParty.post(
      'https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/chatwoot/addWebWidgetInbox',
      headers: {
        'Content-Type' => 'application/json'
      },
      body: {
        shopUrl: shop_url,
        liveChatWebsiteToken: @inbox.channel.website_token,
        liveChatWebsiteURL: @inbox.channel.website_url
      }.to_json
    )
    if response.success?
      render json: response.body
    else
      Rails.logger.error('Error Adding web Widget')
      render json: { error: 'Failed to Add web widget' }, status: response.code
    end
  rescue StandardError => e
    handle_error(e)
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
    @inbox.update!(permitted_params.except(:channel, :assign_even_if_offline, :prompt_agent_for_csat, :csat_format, :csat_question_text))
    update_auto_assignment_config
    update_csat_config
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

  def comment_messageable_status
    messages_to_update = @inbox.messages.where('content_attributes::text LIKE ?', "%#{params[:comment_id]}%")
    Rails.logger.info "SQL: #{messages_to_update.to_sql}"
    Rails.logger.info "Messages to update: #{messages_to_update.count}"
    messages_to_update.find_each do |message|
      Rails.logger.info "Updating message: #{message.id}"
      updated_attributes = message.content_attributes || {}
      updated_attributes[:is_dm_conversation_created] = true
      message.update!(content_attributes: updated_attributes)
      Rails.logger.info "Updated message: #{message.id}"
    end
    render status: :ok, json: { message: 'Messages updated successfully' }
  rescue StandardError => e
    render status: :unprocessable_entity, json: { message: e.message }
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id])
    authorize @inbox, :show?
  end

  def fetch_agent_bot
    @agent_bot = AgentBot.find(params[:agent_bot]) if params[:agent_bot]
  end

  def create_channel
    return unless %w[web_widget api email line telegram whatsapp sms].include?(permitted_params[:channel][:type])

    account_channels_method.create!(permitted_params(channel_type_from_params::EDITABLE_ATTRS)[:channel].except(:type))
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

  def update_auto_assignment_config # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    if params[:assign_even_if_offline].blank? && params[:reopen_pending_conversations].blank? && params[:reassign_on_resolve].blank? && params[:auto_resolve_duplicate_email_conversations].blank? # rubocop:disable Layout/LineLength
      return
    end

    current_config = @inbox.auto_assignment_config || {}

    if params[:assign_even_if_offline].present?
      current_config['assign_even_if_offline'] = ActiveModel::Type::Boolean.new.cast(params[:assign_even_if_offline])
    end

    if params[:reopen_pending_conversations].present?
      current_config['reopen_pending_conversations'] = ActiveModel::Type::Boolean.new.cast(params[:reopen_pending_conversations])
    end

    current_config['reassign_on_resolve'] = ActiveModel::Type::Boolean.new.cast(params[:reassign_on_resolve]) if params[:reassign_on_resolve].present?

    if params[:auto_resolve_duplicate_email_conversations].present?
      current_config['auto_resolve_duplicate_email_conversations'] =
        ActiveModel::Type::Boolean.new.cast(params[:auto_resolve_duplicate_email_conversations])
    end

    @inbox.auto_assignment_config = current_config
    @inbox.save!
  end

  def update_csat_config # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return if params[:prompt_agent_for_csat].blank? && params[:csat_format].blank? && params[:csat_question_text].blank?

    current_config = @inbox.csat_config || {}

    if params[:prompt_agent_for_csat].present?
      current_config['prompt_agent_for_csat'] = ActiveModel::Type::Boolean.new.cast(params[:prompt_agent_for_csat])
    end

    current_config['format'] = params[:csat_format] if params[:csat_format].present?

    current_config['question_text'] = params[:csat_question_text] if params[:csat_question_text].present? || params.key?(:csat_question_text)

    @inbox.csat_config = current_config
    @inbox.save!
  end

  def inbox_attributes
    [:name, :avatar, :greeting_enabled, :greeting_message, :enable_email_collect, :csat_survey_enabled,
     :enable_auto_assignment, :working_hours_enabled, :out_of_office_message, :timezone, :allow_messages_after_resolved,
     :lock_to_single_conversation, :portal_id, :sender_name_type, :business_name, :add_label_to_resolve_conversation,
     :csat_expiry_hours, :csat_allow_resend_after_expiry, :prompt_agent_for_csat, :csat_format, :csat_question_text]
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
end

Api::V1::Accounts::InboxesController.prepend_mod_with('Api::V1::Accounts::InboxesController')
