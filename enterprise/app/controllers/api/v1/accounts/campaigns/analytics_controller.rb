class Api::V1::Accounts::Campaigns::AnalyticsController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 25

  before_action :campaign
  before_action :authorize_campaign
  before_action :ensure_whatsapp_campaign_analytics_enabled!

  def metrics
    render json: delivery_metrics
  end

  def contacts
    recipients = filtered_recipients.includes(:contact).page(current_page).per(RESULTS_PER_PAGE)

    render json: {
      payload: recipients.map { |recipient| recipient_payload(recipient) },
      meta: {
        current_page: recipients.current_page,
        total_pages: recipients.total_pages,
        total_count: recipients.total_count
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
    recipients = @campaign.campaign_recipients
    counts = recipients.group(:status).count

    {
      audience: recipients.count,
      sent: recipients.where.not(source_id: nil).count,
      delivered: counts['delivered'].to_i + counts['read'].to_i,
      read: counts['read'].to_i,
      failed: counts['failed'].to_i,
      skipped: counts['skipped'].to_i,
      status_counts: CampaignRecipient.statuses.keys.index_with { |status| counts[status].to_i }
    }
  end

  def filtered_recipients
    return recipients unless CampaignRecipient.statuses.key?(params[:status])

    recipients.where(status: params[:status])
  end

  def recipients
    @recipients ||= @campaign.campaign_recipients.order(created_at: :desc)
  end

  def recipient_payload(recipient)
    {
      contact: {
        id: recipient.contact.id,
        name: recipient.contact.name,
        phone_number: recipient.contact.phone_number
      },
      status: recipient.status,
      message_content: recipient.message_content,
      error_code: recipient.error_code,
      error_title: recipient.error_title,
      error_message: recipient.error_message
    }
  end

  def current_page
    params[:page].presence || 1
  end
end
