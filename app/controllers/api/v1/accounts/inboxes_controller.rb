class Api::V1::Accounts::InboxesController < Api::V1::Accounts::BaseController # rubocop:disable Metrics/ClassLength
  include Api::V1::InboxesHelper
  before_action :fetch_inbox, except: [:index, :create]
  before_action :fetch_agent_bot, only: [:set_agent_bot]
  # we are already handling the authorization in fetch inbox
  # rubocop:disable Rails/LexicallyScopedActionFilter -- health is defined in InboxHealthManagement concern
  before_action :check_authorization,
                except: [:show, :health, :setup_channel_provider, :import_whatsapp_session, :request_pairing_code]
  # rubocop:enable Rails/LexicallyScopedActionFilter
  before_action :validate_strict_boolean_settings, only: [:create, :update]
  before_action :validate_reopen_owner, only: [:create, :update]

  include Api::V1::Accounts::Concerns::InboxHealthManagement
  include Api::V1::Accounts::Concerns::InboxSecretManagement
  include Api::V1::Accounts::Concerns::BandwidthConfiguration
  before_action :prepare_bandwidth_configuration, only: [:create, :update]

  def index
    @inboxes = inbox_scope
               .includes(:channel, :portal, :working_hours, { avatar_attachment: :blob })
               .order_by_name
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
    continue_update = false

    ActiveRecord::Base.transaction do
      continue_update = update_branded_email_layout
      raise ActiveRecord::Rollback unless continue_update

      inbox_params = permitted_params.except(:channel, :csat_config)
      inbox_params[:csat_config] = format_csat_config(permitted_params[:csat_config]) if permitted_params[:csat_config].present?
      @inbox.update!(inbox_params)
      update_inbox_working_hours
      update_channel if channel_update_required?
    end

    return unless continue_update
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

  def setup_channel_provider
    channel = @inbox.channel

    unless channel.respond_to?(:setup_channel_provider)
      render json: { error: 'Channel does not support setup' }, status: :unprocessable_entity and return
    end

    channel.setup_channel_provider
    head :ok
  rescue Whatsapp::Session::Errors::Error => e
    render_session_error(e)
  end

  # The other way into the same pairing, for an operator who cannot scan the QR.
  # Authorized exactly like setup_channel_provider, and for the same reason: both link a
  # WhatsApp account to an inbox this agent is already assigned to.
  #
  # No phone in the request. The number is the inbox's own, because pairing links
  # whatever phone the code is typed on and the layer quarantines a session whose account
  # is not the inbox's.
  def request_pairing_code
    channel = @inbox.channel

    unless channel.respond_to?(:request_pairing_code)
      render json: { error: 'Channel does not support pairing by code' }, status: :unprocessable_entity and return
    end

    channel.request_pairing_code
    head :ok
  rescue Whatsapp::Session::Errors::Error => e
    render_session_error(e)
  end

  # Hot-loads a WhatsApp Web session extracted by the browser extension into a
  # disconnected Baileys inbox. Authorized like setup_channel_provider (any agent
  # assigned to the inbox, via fetch_inbox -> show?), since connecting a number
  # to an assigned inbox is the same privilege as scanning a QR for it.
  def import_whatsapp_session
    channel = @inbox.channel

    unless channel.is_a?(Channel::Whatsapp) && channel.provider == 'baileys'
      render json: { error: 'Session import is only supported for Baileys WhatsApp channels' },
             status: :unprocessable_entity and return
    end

    session = import_session_params[:session].to_h
    render json: { error: 'Session payload is required' }, status: :unprocessable_entity and return if session.blank?

    channel.import_session(
      session: session,
      candidate_index: import_session_params[:candidate_index].to_i
    )
    head :ok
  rescue Whatsapp::Session::Errors::ProviderUnavailable
    render json: { error: 'WhatsApp provider is currently unavailable. Please try again.' }, status: :service_unavailable
  end

  def disconnect_channel_provider
    channel = @inbox.channel

    unless channel.respond_to?(:disconnect_channel_provider)
      render json: { error: 'Channel does not support disconnect' }, status: :unprocessable_entity and return
    end

    channel.disconnect_channel_provider
    channel.update_provider_connection!(connection: 'close') if channel.respond_to?(:update_provider_connection!)
    head :ok
  rescue Whatsapp::Session::Errors::Error => e
    # Marked closed on success only. A session the provider refused to end is still open,
    # and recording it as closed is how an operator ends up with a connected number, a
    # dashboard that says otherwise, and no reason to try again.
    render_session_error(e)
  end

  def convert_provider
    channel = @inbox.channel

    unless channel.respond_to?(:convert_provider!)
      render json: { error: 'Channel does not support provider conversion' }, status: :unprocessable_entity and return
    end

    new_provider = params.require(:provider)
    new_provider_config = (params.permit(provider_config: {})[:provider_config] || {}).to_h

    channel.convert_provider!(new_provider: new_provider, new_provider_config: new_provider_config)
    render :show
  rescue ActionController::ParameterMissing => e
    render json: { message: e.message }, status: :bad_request
  rescue ActiveRecord::RecordInvalid => e
    render json: { message: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Provider conversion failed for inbox #{@inbox.id}: #{e.class}: #{e.message}"
    render json: { message: 'Provider conversion failed. Please check your credentials and the previous provider session, then try again.' },
           status: :unprocessable_entity
  end

  def destroy
    ::DeleteObjectJob.perform_later(@inbox, Current.user, request.ip) if @inbox.present?
    render status: :ok, json: { message: I18n.t('messages.inbox_deletetion_response') }
  end

  def on_whatsapp
    params.require(:phone_number)
    phone_number = params[:phone_number]
    channel = @inbox.channel

    unless channel.respond_to?(:on_whatsapp)
      render json: { error: 'Channel does not support whatsapp check' }, status: :unprocessable_entity and return
    end

    deadline = ActiveModel::Type::Boolean.new.cast(params[:advisory]) ? :hint : :provider
    response = channel.on_whatsapp(phone_number, deadline: deadline)

    render json: response, status: :ok
  end

  private

  # The session layer's errors are answers, not crashes: a token typed wrong, an instance
  # that is down, a provider that is rate limiting, a connect refused rather than
  # attempted because the number is quarantined on a provider that cannot unpair. Both
  # actions above are called straight from the pairing UI, which shows what comes back, so
  # a 500 is a blank wall where a sentence belongs.
  #
  # Unauthorized and InvalidConfig are the operator's to fix and say so with a 422, even
  # though they sit under ProviderUnavailable; retrying them changes nothing.
  def render_session_error(error)
    operator_fixable = error.is_a?(Whatsapp::Session::Errors::Unauthorized) ||
                       error.is_a?(Whatsapp::Session::Errors::InvalidConfig)
    status = if error.is_a?(Whatsapp::Session::Errors::RateLimited)
               :too_many_requests
             elsif error.is_a?(Whatsapp::Session::Errors::ProviderUnavailable) && !operator_fixable
               :service_unavailable
             else
               :unprocessable_entity
             end

    render json: { error: error.message, code: error.class::CODE }, status: status
  end

  STRICT_BOOLEAN_SETTINGS = %i[drop_assignee_outside_team_on_reopen restrict_assignment_to_working_hours].freeze

  # Strong params would cast "yes", 1 or "" into a boolean (or nil, which the column refuses
  # with a 500), so only a JSON boolean is accepted.
  def validate_strict_boolean_settings
    invalid = STRICT_BOOLEAN_SETTINGS.find { |key| params.key?(key) && [true, false].exclude?(params[key]) }
    return if invalid.nil?

    render_could_not_create_error("#{invalid} must be true or false")
  end

  # The enum would take an integer for its index and strong params would cast "6" or "abc" for the
  # hours, so only the documented JSON types get through; the model validates the values.
  def validate_reopen_owner
    if params.key?(:reopen_owner) && !params[:reopen_owner].is_a?(String)
      return render_could_not_create_error('reopen_owner must be one of agent_bot, assignee, assignee_within_window')
    end
    return unless params.key?(:reopen_owner_window_hours)
    return if params[:reopen_owner_window_hours].nil? || params[:reopen_owner_window_hours].is_a?(Integer)

    render_could_not_create_error('reopen_owner_window_hours must be an integer or null')
  end

  def inbox_scope = policy_scope(Current.account.inboxes)

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id])
    authorize @inbox, :show?
  end

  # The session is opaque credentials forwarded verbatim to the Baileys API,
  # which validates its schema. We still permit an explicit shape (rather than
  # permit!) so nothing unexpected is forwarded. camelCase keys match the
  # extractor's output.
  def import_session_params
    params.permit(
      :candidate_index,
      session: [
        :registrationId, :advSecretKey, :id, :lid, :platform, :pushName, :routingInfo,
        { noiseCandidates: %i[private public] },
        { identityKey: %i[private public] },
        { account: %i[details accountSignatureKey accountSignature deviceSignature] },
        { signedPreKey: %i[keyId private public signature] }
      ]
    )
  end

  def fetch_agent_bot
    @agent_bot = AgentBot.accessible_to(Current.account).find(params[:agent_bot]) if params[:agent_bot]
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
    @inbox.channel.update!(permitted_params(channel_attributes)[:channel])
    @inbox.channel.reauthorized! if @inbox.channel.respond_to?(:reauthorized!)
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
      :survey_rules => {
        'operator' => config.dig('survey_rules', 'operator') || 'contains',
        'values' => config.dig('survey_rules', 'values') || []
      },
      'button_text' => config['button_text'] || 'Please rate us',
      'language' => config['language'] || 'en'
    }
    format_template_config(config, formatted)
    formatted
  end

  def format_template_config(config, formatted)
    formatted['template'] = config['template'] if config['template'].present?
  end

  def update_branded_email_layout
    return true unless params.key?(:branded_email_layout)

    branded_email_layout = normalized_branded_email_layout

    unless Current.account.feature_enabled?(:branded_email_templates)
      return true if branded_email_layout.blank?

      render_could_not_create_error('Branded email templates feature is not enabled')
      return false
    end

    unless @inbox.email?
      return true if branded_email_layout.blank?

      render_could_not_create_error('Branded email layout is only supported for email inboxes')
      return false
    end

    @inbox.update_branded_email_layout!(branded_email_layout)
    true
  rescue ActiveRecord::RecordInvalid => e
    render_could_not_create_error(e.record.errors.full_messages.join(', '))
    false
  end

  def normalized_branded_email_layout = params[:branded_email_layout] == 'null' ? nil : params[:branded_email_layout]

  def inbox_attributes
    [:name, :avatar, :greeting_enabled, :greeting_message, :enable_email_collect, :csat_survey_enabled,
     :enable_auto_assignment, :working_hours_enabled, :out_of_office_message, :timezone, :allow_messages_after_resolved,
     :lock_to_single_conversation, :prevent_assignment_takeover, :restrict_assignment_to_working_hours, :drop_assignee_outside_team_on_reopen,
     :portal_id, :sender_name_type, :business_name,
     :reopen_owner, :reopen_owner_window_hours,
     { csat_config: [:display_type, :message, :button_text, :language,
                     { survey_rules: [:operator, { values: [] }],
                       template: [:name, :template_id, :friendly_name, :content_sid, :approval_sid,
                                  :created_at, :linked_at, :language, :source, :status, { body_variables: {} }] }] }]
  end

  def permitted_params(channel_attributes = [])
    # We will remove this line after fixing https://linear.app/chatwoot/issue/CW-1567/null-value-passed-as-null-string-to-backend
    params.each { |k, v| params[k] = params[k] == 'null' ? nil : v }
    params.permit(*inbox_attributes, channel: [:type, *channel_attributes])
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
    channel_type.constantize.const_defined?(:EDITABLE_ATTRS) ? channel_type.constantize::EDITABLE_ATTRS.presence : []
  end
end

Api::V1::Accounts::InboxesController.prepend_mod_with('Api::V1::Accounts::InboxesController')
