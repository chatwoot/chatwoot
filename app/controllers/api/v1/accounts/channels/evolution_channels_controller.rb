class Api::V1::Accounts::Channels::EvolutionChannelsController < Api::V1::Accounts::BaseController
  include Api::V1::InboxesHelper
  before_action :authorize_request
  before_action :set_user

  def create
    params = permitted_params(channel_type_from_params::EDITABLE_ATTRS)[:channel].except(:type)
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
      Evolution::ManagerService.new.create(@inbox.account_id, permitted_params[:name], evolution_api_url,
                                           evolution_api_key, @user.access_token.token)
    end

    Rails.logger.info("Evolution channel created successfully: #{@inbox.id}")
    render json: @inbox, status: :created
  rescue CustomExceptions::Evolution::Base => e
    render_evolution_error(e)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Database validation failed for Evolution channel: #{e.message}")
    render_evolution_error(
      CustomExceptions::Evolution::InvalidConfiguration.new(details: "Database validation failed: #{e.message}")
    )
  rescue StandardError => e
    Rails.logger.error("Unexpected error creating Evolution channel: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render_evolution_error(
      CustomExceptions::Evolution::InvalidConfiguration.new(details: "Unexpected error: #{e.message}")
    )
  end

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

  def create_channel(webhook_url)
    return unless %w[api whatsapp].include?(permitted_params[:channel][:type])

    params = permitted_params(channel_type_from_params::EDITABLE_ATTRS)[:channel].except(:type, :api_key)
    params[:webhook_url] = "#{webhook_url}/chatwoot/webhook/#{permitted_params[:name]}"
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
