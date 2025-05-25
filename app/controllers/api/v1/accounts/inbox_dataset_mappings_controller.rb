class Api::V1::Accounts::InboxDatasetMappingsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_inbox
  before_action :set_mapping, only: [:show, :update, :destroy]

  def index
    @mappings = @inbox.inbox_dataset_mappings
                      .includes(:dataset_configuration)
                      .order('dataset_configurations.name')

    render json: {
      data: @mappings.map(&:summary_data),
      inbox: {
        id: @inbox.id,
        name: @inbox.name,
        channel_type: @inbox.channel.class.name
      }
    }
  end

  def show
    render json: @mapping.detailed_data
  end

  def create
    @mapping = @inbox.inbox_dataset_mappings.build(mapping_params)

    # Validate that the dataset configuration supports this inbox's channel
    unless @mapping.dataset_configuration.supports_channel?(@inbox.channel)
      render json: {
        error: "Dataset configuration '#{@mapping.dataset_configuration.name}' does not support #{@inbox.channel.class.name} channels"
      }, status: :unprocessable_entity
      return
    end

    if @mapping.save
      render json: {
        data: @mapping.detailed_data,
        message: 'Dataset mapping created successfully'
      }, status: :created
    else
      render json: {
        error: 'Failed to create dataset mapping',
        details: @mapping.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @mapping.update(mapping_params)
      render json: {
        data: @mapping.detailed_data,
        message: 'Dataset mapping updated successfully'
      }
    else
      render json: {
        error: 'Failed to update dataset mapping',
        details: @mapping.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @mapping.destroy
      render json: { message: 'Dataset mapping removed successfully' }
    else
      render json: {
        error: 'Failed to remove dataset mapping',
        details: @mapping.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # Get available dataset configurations for this inbox
  def available_datasets
    channel_type = @inbox.channel.class.name
    platform = case channel_type
               when 'Channel::FacebookPage'
                 if @inbox.channel.instagram_id.present?
                   ['facebook', 'instagram', 'meta']
                 else
                   ['facebook', 'meta']
                 end
               else
                 []
               end

    available_configs = Current.account.dataset_configurations
                                      .enabled
                                      .where(platform: platform)
                                      .where.not(
                                        id: @inbox.inbox_dataset_mappings.pluck(:dataset_configuration_id)
                                      )

    render json: {
      data: available_configs.map(&:summary_data),
      supported_platforms: platform
    }
  end

  private

  def set_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def set_mapping
    @mapping = @inbox.inbox_dataset_mappings.find(params[:id])
  end

  def check_authorization
    authorize(InboxDatasetMapping)
  end

  def mapping_params
    params.require(:inbox_dataset_mapping).permit(
      :dataset_configuration_id,
      :enabled,
      override_config: {}
    )
  end
end
