class Api::V1::Accounts::InboxesController < Api::V1::Accounts::BaseController # rubocop:disable Metrics/ClassLength
  include Api::V1::InboxesHelper
  before_action :fetch_inbox, except: [:index, :create]
  before_action :fetch_agent_bot, only: [:set_agent_bot]
  before_action :validate_limit, only: [:create]
  before_action :check_authorization, except: [:show]

  def index
    @inboxes = policy_scope(Current.account.inboxes.order_by_name.includes(:channel, { avatar_attachment: [:blob] }))
  end

  def show; end

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
    return render_expired_subscription unless Current.account.subscriptions.active.exists?

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
    @inbox.update!(permitted_params.except(:channel))
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

  def whatsapp_qr
    @channel = @inbox.channel

    begin
      qr_data = @channel.get_qr_code
      render json: {
        success: true,
        qr_code: qr_data.dig('data', 'qr'),
        message: 'QR Code generated successfully'
      }
    rescue StandardError => e
      render json: {
        success: false,
        message: "Failed to generate QR code: #{e.message}"
      }, status: :unprocessable_entity
    end
  end

  def whatsapp_status
    @channel = @inbox.channel

    force_real_time = params[:real_time] == 'true'

    begin
      status = if force_real_time && @channel.respond_to?(:real_time_status)
                 @channel.real_time_status
               else
                 @channel.session_status
               end

      result = build_status_response(status)

      render json: result
    rescue StandardError => e
      Rails.logger.error "❌ WhatsApp status error: #{e.message}"
      render json: error_status_response(e.message)
    end
  end

  def whatsapp_restart_session # rubocop:disable Metrics/MethodLength
    @channel = @inbox.channel

    begin
      if @channel.respond_to?(:restart_session_for_rescan)
        result = @channel.restart_session_for_rescan

        if result[:success]
          render json: {
            success: true,
            message: result[:message],
            status: result[:status]
          }
        else
          Rails.logger.error 'Restart session FAILED - rendering error response'
          render json: {
            success: false,
            message: result[:message],
            error: result[:error]
          }, status: :unprocessable_entity
        end
      else
        Rails.logger.warning 'Channel does not respond to restart_session_for_rescan'
        render json: {
          success: false,
          message: 'Restart session not supported for this channel type'
        }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error "WhatsApp restart session error: #{e.message}"
      render json: {
        success: false,
        message: "Failed to restart session: #{e.message}"
      }, status: :internal_server_error
    end
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id])
    authorize @inbox, :show?
  end

  def fetch_agent_bot
    @agent_bot = @inbox.agent_bot
  end

  def build_status_response(status) # rubocop:disable Metrics/MethodLength
    waha_status = map_to_waha_status(status)

    attempts_info = {}
    if @channel.respond_to?(:read_mismatch_attempts_from_cache)
      current_attempts = @channel.read_mismatch_attempts_from_cache
      if current_attempts.positive?
        attempts_info = {
          current_attempts: current_attempts,
          max_attempts: 3,
          remaining_attempts: 3 - current_attempts
        }
      end
    end

    base_response = {
      success: true,
      message: 'session info fetched successfully',
      connected: waha_status == 'logged_in',
      status: waha_status,
      data: {
        status: waha_status,
        connected: waha_status == 'logged_in'
      }
    }

    # Add attempts info if available
    if attempts_info.any?
      base_response[:attempts] = attempts_info
      base_response[:data][:attempts] = attempts_info
    end

    base_response
  end

  def error_status_response(error_message)
    {
      success: false,
      connected: false,
      message: error_message,
      data: {
        status: 'not_logged_in',
        connected: false
      }
    }
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

  def inbox_attributes
    [:name, :avatar, :greeting_enabled, :greeting_message, :enable_email_collect, :csat_survey_enabled,
     :enable_auto_assignment, :working_hours_enabled, :out_of_office_message, :timezone, :allow_messages_after_resolved,
     :lock_to_single_conversation, :portal_id, :sender_name_type, :business_name]
  end

  def map_to_waha_status(status)
    actual_status = status.dig('data', 'status')
    status_map = {
      'connected' => 'logged_in',
      'authenticated' => 'logged_in',
      'ready' => 'logged_in',
      'logged_in' => 'logged_in',
      'pending_validation' => 'pending_validation',
      'waiting' => 'pending_validation',
      'waiting_for_qr' => 'waiting_for_qr',
      'disconnected' => 'not_logged_in',
      'not_logged_in' => 'not_logged_in'
    }

    status_map.fetch(actual_status&.downcase, 'not_logged_in')
  end

  def permitted_params(channel_attributes = [])
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
      'sms' => Channel::Sms,
      'whatsapp_unofficial' => Channel::WhatsappUnofficial
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
