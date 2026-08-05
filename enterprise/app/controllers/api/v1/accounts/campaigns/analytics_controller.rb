class Api::V1::Accounts::Campaigns::AnalyticsController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 25

  before_action :campaign
  before_action :authorize_campaign
  before_action :ensure_whatsapp_campaign_analytics_enabled!

  def metrics
    render json: delivery_metrics
  end

  def contacts
    deliveries = filtered_deliveries.includes(:contact).page(current_page).per(RESULTS_PER_PAGE)

    render json: {
      payload: deliveries.map { |delivery| delivery_payload(delivery) },
      meta: {
        current_page: deliveries.current_page,
        total_pages: deliveries.total_pages,
        total_count: deliveries.total_count
      }
    }
  end

  private

  def campaign
    @campaign ||= Current.account.campaigns.find_by!(display_id: params[:campaign_id])
  end

  def ensure_whatsapp_campaign_analytics_enabled!
    return if @campaign.one_off? && @campaign.inbox.inbox_type == 'Whatsapp' && Current.account.feature_enabled?(:whatsapp_campaign)

    raise Pundit::NotAuthorizedError
  end

  def authorize_campaign
    authorize @campaign, :show?
  end

  def delivery_metrics
    metric_deliveries = @campaign.campaign_deliveries
    counts = metric_deliveries.group(:status).count

    {
      audience: metric_deliveries.count,
      sent: metric_deliveries.where.not(source_id: nil).count,
      delivered: counts['delivered'].to_i + counts['read'].to_i,
      read: counts['read'].to_i,
      failed: counts['failed'].to_i,
      skipped: counts['skipped'].to_i,
      status_counts: CampaignDelivery.statuses.keys.index_with { |status| counts[status].to_i }
    }
  end

  def filtered_deliveries
    return deliveries unless CampaignDelivery.statuses.key?(params[:status])

    deliveries.where(status: params[:status])
  end

  def deliveries
    @deliveries ||= @campaign.campaign_deliveries.order(created_at: :desc)
  end

  def delivery_payload(delivery)
    {
      contact: {
        id: delivery.contact.id,
        name: delivery.contact.name,
        phone_number: delivery.contact.phone_number
      },
      status: delivery.status,
      message_content: delivery.message_content,
      error_code: delivery.error_code,
      error_title: delivery.error_title,
      error_message: delivery.error_message
    }
  end

  def current_page
    params[:page].presence || 1
  end
end
