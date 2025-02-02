class Api::V1::Accounts::CampaignsController < Api::V1::Accounts::BaseController
  before_action :campaign, except: [:index, :create]
  before_action :check_authorization
  before_action :validate_campaign_params, only: [:create, :update]

  def index
    @campaigns = Current.account.campaigns
    render json: @campaigns
  end

  def show
    render json: @campaign
  end

  def create
    ActiveRecord::Base.transaction do
      # Get contact objects - ensure we're working with Contact objects
      contact_objects = Current.account.contacts.where(id: params[:campaign][:contacts])

      # Prepare campaign parameters without contacts
      campaign_params_result = campaign_params.except(:contacts)

      # Set campaign type if template is present
      campaign_params_result[:campaign_type] = 'whatsapp' if campaign_params_result[:template_id].present?

      # Create campaign without contacts first
      @campaign = Current.account.campaigns.new(campaign_params_result)

      # Validate contacts existence
      validate_contacts if contact_objects.present?

      if @campaign.save
        # Create campaign_contacts associations using the actual Contact objects
        contact_objects.each do |contact|
          CampaignContact.create!(
            campaign: @campaign,
            contact: contact,
            status: 'pending'
          )
        end

        # Reload to ensure we have all associations
        @campaign.reload
        render json: @campaign, status: :created
      else
        render json: {
          error: @campaign.errors.full_messages.join(', '),
          details: @campaign.errors.details
        }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: "Failed to create campaign contacts: #{e.message}",
      class: e.class.to_s
    }, status: :unprocessable_entity
  rescue StandardError => e
    render json: {
      error: "Failed to create campaign: #{e.message}",
      class: e.class.to_s
    }, status: :unprocessable_entity
  end

  def fetch_campaign_contacts
    processed_contacts = @campaign.processed_contacts.map do |contact|
      {
        id: contact.id,
        name: contact.name,
        phone_number: contact.phone_number,
        processed_at: contact.campaign_contacts.find_by(campaign: @campaign)&.processed_at
      }
    end

    failed_contacts = @campaign.failed_contacts.map do |contact|
      {
        id: contact.id,
        name: contact.name,
        phone_number: contact.phone_number,
        error_message: contact.campaign_contacts.find_by(campaign: @campaign)&.error_message
      }
    end

    read_contacts = @campaign.read_contacts.map do |contact|
      {
        id: contact.id,
        name: contact.name,
        phone_number: contact.phone_number,
        processed_at: contact.campaign_contacts.find_by(campaign: @campaign)&.updated_at
      }
    end

    delivered_contacts = @campaign.delivered_contacts.map do |contact|
      {
        id: contact.id,
        name: contact.name,
        phone_number: contact.phone_number,
        processed_at: contact.campaign_contacts.find_by(campaign: @campaign)&.updated_at
      }
    end

    replied_contacts = @campaign.replied_contacts.map do |contact|
      {
        id: contact.id,
        name: contact.name,
        phone_number: contact.phone_number,
        processed_at: contact.campaign_contacts.find_by(campaign: @campaign)&.updated_at
      }
    end

    pending_contacts = @campaign.pending_contacts.map do |contact|
      {
        id: contact.id,
        name: contact.name,
        phone_number: contact.phone_number
      }
    end

    render json: {
      processed_contacts: processed_contacts,
      failed_contacts: failed_contacts,
      read_contacts: read_contacts,
      delivered_contacts: delivered_contacts,
      replied_contacts: replied_contacts,
      pending_contacts: pending_contacts
    }
  end

  def update
    if @campaign.update(campaign_params)
      render json: @campaign
    else
      render json: { error: @campaign.errors.full_messages.join(', ') },
             status: :unprocessable_entity
    end
  end

  def destroy
    @campaign.destroy!
    head :ok
  end

  private

  def campaign
    @campaign ||= Current.account.campaigns.find_by!(display_id: params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(
      :title,
      :description,
      :message,
      :enabled,
      :trigger_only_during_business_hours,
      :template_id,
      :inbox_id,
      :sender_id,
      :scheduled_at,
      contacts: [],
      audience: [:type, :id],
      trigger_rules: {}
    ).tap do |whitelisted|
      # Explicitly set default values if not provided
      whitelisted[:enabled] = true if whitelisted[:enabled].nil?
      whitelisted[:trigger_only_during_business_hours] = false if whitelisted[:trigger_only_during_business_hours].nil?
    end
  end

  def validate_campaign_params
    if params[:campaign].blank?
      render json: { error: 'Campaign parameters are required' },
             status: :unprocessable_entity
      return
    end

    required_params = [:title, :inbox_id]
    missing_params = required_params.select { |param| params[:campaign][param].blank? }

    return unless missing_params.any?

    render json: {
      error: "Missing required parameters: #{missing_params.join(', ')}"
    }, status: :unprocessable_entity
  end

  def validate_contacts
    contact_ids = params[:campaign][:contacts]
    return if contact_ids.blank?

    existing_contacts = Current.account.contacts
                               .where(id: contact_ids)
                               .pluck(:id)

    missing_contacts = contact_ids - existing_contacts

    return unless missing_contacts.any?

    raise ActiveRecord::RecordInvalid, "Invalid contacts: #{missing_contacts.join(', ')}"
  end
end
