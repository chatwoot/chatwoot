class Api::V1::Accounts::Channels::EvolutionChannelsController < Api::V1::Accounts::BaseController
  include Api::V1::InboxesHelper

  before_action :authorize_request
  before_action :set_user

  # IMPORTANT: rescue_from handlers are checked in REVERSE order (last defined = first checked)
  # So we put the most general handler (StandardError) first, and most specific (Evolution::Base) last
  rescue_from StandardError, with: :handle_standard_error
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  rescue_from CustomExceptions::Evolution::Base, with: :render_evolution_error

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def create
    channel_type = channel_type_from_params
    unless channel_type
      return render_evolution_error(
        CustomExceptions::Evolution::InvalidConfiguration.new(details: 'Invalid or missing channel type')
      )
    end

    params = permitted_params(channel_type::EDITABLE_ATTRS)[:channel].except(:type)
    evolution_api_url = ENV.fetch('EVOLUTION_API_URL', params[:webhook_url])
    evolution_api_key = ENV.fetch('EVOLUTION_API_KEY', params[:api_key])

    if evolution_api_url.blank?
      return render_evolution_error(
        CustomExceptions::Evolution::InvalidConfiguration.new(details: 'Evolution API URL is missing')
      )
    end

    Rails.logger.info("Creating Evolution channel for account: #{Current.account.id}, name: #{permitted_params[:name]}")

    ActiveRecord::Base.transaction do
      # Validate Evolution API connection before creating channel
      validate_evolution_service(evolution_api_url, evolution_api_key, permitted_params[:name])

      channel = create_channel(evolution_api_url)
      @inbox = Current.account.inboxes.build(
        {
          name: inbox_name(channel),
          channel: channel
        }.merge(
          permitted_params.except(:channel)
        )
      )
      @inbox.save!

      # Create Evolution instance
      user_token = @user.access_token&.token
      raise CustomExceptions::Evolution::InvalidConfiguration.new(details: 'User access token not found') if user_token.blank?

      Evolution::ManagerService.new.create(@inbox.account_id, permitted_params[:name], evolution_api_url,
                                           evolution_api_key, user_token)
    end

    Rails.logger.info("Evolution channel created successfully: #{@inbox.id}")
    render json: @inbox, status: :created
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def authorize_request
    authorize ::Inbox
  end

  def set_user
    @user = current_user
  end

  def validate_evolution_service(_evolution_api_url, _evolution_api_key, instance_name)
    # Check if instance name already exists by calling Evolution API
    # This is a preliminary check before actual creation
    Rails.logger.info("Validating Evolution service accessibility for instance: #{instance_name}")

    # For now, we rely on the ManagerService validation
    # Future enhancement: Add a health check endpoint call here
  end

  def handle_record_invalid(exception)
    Rails.logger.error("Database validation failed for Evolution channel: #{exception.message}")
    render_evolution_error(
      CustomExceptions::Evolution::InvalidConfiguration.new(details: "Database validation failed: #{exception.message}")
    )
  end

  def handle_standard_error(exception)
    Rails.logger.error("Unexpected error creating Evolution channel: #{exception.class} - #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))
    render_evolution_error(
      CustomExceptions::Evolution::InvalidConfiguration.new(details: "Unexpected error: #{exception.message}")
    )
  end

  def render_evolution_error(exception)
    error_response = {
      error: exception.message,
      error_code: exception.error_code,
      status: exception.http_status
    }

    # Add additional context for debugging (only in non-production)
    unless Rails.env.production?
      error_response[:details] = {
        exception_class: exception.class.name,
        data: exception.instance_variable_get(:@data)
      }
    end

    Rails.logger.error("Evolution API Error: #{error_response}")
    render json: error_response, status: exception.http_status
  end

  def create_channel(_webhook_url)
    return unless %w[api whatsapp].include?(permitted_params[:channel][:type])

    channel_type = channel_type_from_params
    return unless channel_type

    params = permitted_params(channel_type::EDITABLE_ATTRS)[:channel].except(:type, :api_key, :webhook_url)
    # For Evolution API, we don't store webhook_url in the channel model
    # The webhook URL is managed by the Evolution API service
    account_channels_method.create!(params)
  end

  def inbox_attributes
    [:name]
  end

  def permitted_params(channel_attributes = [])
    # We will remove this line after fixing https://linear.app/chatwoot/issue/CW-1567/null-value-passed-as-null-string-to-backend
    params.each { |k, v| params[k] = params[k] == 'null' ? nil : v }

    params.permit(
      *inbox_attributes,
      channel: [:type, :api_key, *channel_attributes]
    )
  end

  def channel_type_from_params
    {
      'api' => Channel::Api,
      'whatsapp' => Channel::Whatsapp
    }[permitted_params[:channel][:type]]
  end
end
