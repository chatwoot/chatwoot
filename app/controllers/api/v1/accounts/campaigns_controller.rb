class Api::V1::Accounts::CampaignsController < Api::V1::Accounts::BaseController
  before_action :campaign, except: [:index, :create, :audience_count]
  before_action :check_authorization

  def index
    @campaigns = Current.account.campaigns
  end

  def audience_count
    render json: { count: audience_contacts.count }
  end

  def show; end

  def create
    @campaign = Current.account.campaigns.create!(campaign_params)
  end

  def update
    @campaign.update!(campaign_params)
  end

  def destroy
    @campaign.destroy!
    head :ok
  end

  private

  def campaign
    @campaign ||= Current.account.campaigns.find_by(display_id: params[:id])
  end

  def audience_contacts
    labels = Current.account.labels.where(id: params[:label_ids]).pluck(:title)
    return Contact.none if labels.blank?

    Current.account.contacts.tagged_with(labels, any: true).where.not(phone_number: [nil, ''])
  end

  def campaign_params
    params.require(:campaign).permit(:title, :description, :message, :enabled, :trigger_only_during_business_hours, :inbox_id, :sender_id,
                                     :scheduled_at, audience: [:type, :id], trigger_rules: {}, template_params: {})
  end
end
