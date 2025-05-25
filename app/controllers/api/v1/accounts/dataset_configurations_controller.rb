class Api::V1::Accounts::DatasetConfigurationsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_dataset_configuration, only: [:show, :update, :destroy, :test_connection, :pixels, :generate_token]

  def index
    @dataset_configurations = Current.account.dataset_configurations
                                            .includes(:inboxes)
                                            .order(:name)

    render json: {
      data: @dataset_configurations.map(&:summary_data),
      total_count: @dataset_configurations.count
    }
  end

  def show
    render json: @dataset_configuration.detailed_data
  end

  def create
    @dataset_configuration = Current.account.dataset_configurations.build(dataset_configuration_params)

    if @dataset_configuration.save
      render json: {
        data: @dataset_configuration.detailed_data,
        message: 'Dataset configuration created successfully'
      }, status: :created
    else
      render json: {
        error: 'Failed to create dataset configuration',
        details: @dataset_configuration.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @dataset_configuration.update(dataset_configuration_params)
      render json: {
        data: @dataset_configuration.detailed_data,
        message: 'Dataset configuration updated successfully'
      }
    else
      render json: {
        error: 'Failed to update dataset configuration',
        details: @dataset_configuration.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @dataset_configuration.destroy
      render json: { message: 'Dataset configuration deleted successfully' }
    else
      render json: {
        error: 'Failed to delete dataset configuration',
        details: @dataset_configuration.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def test_connection
    begin
      result = @dataset_configuration.test_connection

      if result[:success]
        render json: {
          success: true,
          message: 'Dataset connection test successful',
          details: result[:details]
        }
      else
        render json: {
          success: false,
          error: result[:error],
          details: result[:details]
        }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("Dataset connection test failed: #{e.message}")
      render json: {
        success: false,
        error: 'Connection test failed. Please check your configuration.'
      }, status: :internal_server_error
    end
  end

  def pixels
    begin
      service = case @dataset_configuration.platform
                when 'facebook'
                  Facebook::GetPixelsService.new(account: Current.account)
                when 'instagram'
                  Instagram::GetPixelsService.new(account: Current.account)
                when 'meta'
                  Meta::GetPixelsService.new(account: Current.account)
                else
                  raise "Unsupported platform: #{@dataset_configuration.platform}"
                end

      result = service.get_pixels

      if result[:success]
        render json: {
          success: true,
          pixels: result[:pixels],
          message: "Found #{result[:pixels].length} pixels"
        }
      else
        render json: {
          success: false,
          error: result[:error],
          pixels: []
        }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("Error fetching pixels: #{e.message}")
      render json: {
        success: false,
        error: 'Failed to fetch pixels. Please check your platform connection.',
        pixels: []
      }, status: :internal_server_error
    end
  end

  def generate_token
    pixel_id = params[:pixel_id]

    if pixel_id.blank?
      render json: {
        success: false,
        error: 'Pixel ID is required'
      }, status: :unprocessable_entity
      return
    end

    begin
      service = case @dataset_configuration.platform
                when 'facebook'
                  Facebook::GenerateTokenService.new(account: Current.account, pixel_id: pixel_id)
                when 'instagram'
                  Instagram::GenerateTokenService.new(account: Current.account, pixel_id: pixel_id)
                when 'meta'
                  Meta::GenerateTokenService.new(account: Current.account, pixel_id: pixel_id)
                else
                  raise "Unsupported platform: #{@dataset_configuration.platform}"
                end

      result = service.generate_conversions_api_token

      if result[:success]
        render json: {
          success: true,
          access_token: result[:access_token],
          message: 'Access token generated successfully'
        }
      else
        render json: {
          success: false,
          error: result[:error]
        }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("Error generating access token: #{e.message}")
      render json: {
        success: false,
        error: 'Failed to generate access token. Please check your platform permissions.'
      }, status: :internal_server_error
    end
  end

  # Get available inboxes for mapping
  def available_inboxes
    platform = params[:platform] || 'facebook'
    
    inboxes = case platform
              when 'facebook'
                Current.account.inboxes.joins(:channel)
                              .where(channels: { type: 'Channel::FacebookPage' })
              when 'instagram'
                Current.account.inboxes.joins(:channel)
                              .where(channels: { type: 'Channel::FacebookPage' })
                              .where.not(channels: { instagram_id: [nil, ''] })
              when 'meta'
                Current.account.inboxes.joins(:channel)
                              .where(channels: { type: 'Channel::FacebookPage' })
              else
                Current.account.inboxes.none
              end

    render json: {
      data: inboxes.map do |inbox|
        {
          id: inbox.id,
          name: inbox.name,
          channel_type: inbox.channel.class.name,
          platform_id: inbox.channel.try(:page_id) || inbox.channel.try(:instagram_id)
        }
      end
    }
  end

  private

  def set_dataset_configuration
    @dataset_configuration = Current.account.dataset_configurations.find(params[:id])
  end

  def check_authorization
    authorize(DatasetConfiguration)
  end

  def dataset_configuration_params
    params.require(:dataset_configuration).permit(
      :name,
      :platform,
      :pixel_id,
      :access_token,
      :test_event_code,
      :default_event_name,
      :default_event_value,
      :default_currency,
      :auto_send_conversions,
      :enabled,
      :description,
      additional_config: {}
    )
  end
end
