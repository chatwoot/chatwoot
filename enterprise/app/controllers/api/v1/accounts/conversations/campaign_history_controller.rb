class Api::V1::Accounts::Conversations::CampaignHistoryController < Api::V1::Accounts::Conversations::BaseController
  RESULTS_PER_PAGE = 25

  before_action :ensure_whatsapp_campaign_enabled!
  before_action :validate_cursor

  def index
    recipients = campaign_recipients
    if params.key?(:before)
      cursor = recipients.find(params[:before])
      recipients = recipients.where('(sent_at, id) < (?, ?)', cursor.sent_at, cursor.id)
    end

    page = recipients.includes(:campaign).order(sent_at: :desc, id: :desc).limit(RESULTS_PER_PAGE + 1).to_a
    has_more = page.length > RESULTS_PER_PAGE
    page = page.first(RESULTS_PER_PAGE)

    render json: {
      payload: page.map { |recipient| recipient_payload(recipient) },
      meta: {
        next_before: has_more ? page.last.id : nil,
        first_message_id: @conversation.messages.minimum(:id)
      }
    }
  end

  private

  def ensure_whatsapp_campaign_enabled!
    return if @conversation.inbox.whatsapp? && Current.account.feature_enabled?(:whatsapp_campaign)

    raise Pundit::NotAuthorizedError
  end

  def validate_cursor
    return unless params.key?(:before)
    return if params[:before].is_a?(String) && params[:before].match?(/\A[1-9]\d*\z/)

    render json: { error: 'before must be a positive recipient ID' }, status: :unprocessable_entity
  end

  def campaign_recipients
    next_conversation = Current.account.conversations.where(contact_inbox_id: @conversation.contact_inbox_id)
                               .where('(created_at, id) > (?, ?)', @conversation.created_at, @conversation.id)
                               .order(:created_at, :id).first
    recipients = @conversation.contact.campaign_recipients.where(account_id: Current.account.id, inbox_id: @conversation.inbox_id)
                              .where(contact_inbox_id: @conversation.contact_inbox_id)
                              .where(sent_at: @conversation.created_at..)
    next_conversation ? recipients.where('sent_at < ?', next_conversation.created_at) : recipients
  end

  def recipient_payload(recipient)
    {
      id: recipient.id,
      campaign: { id: recipient.campaign.display_id, title: recipient.campaign.title },
      message_content: recipient.message_content,
      source_id: recipient.source_id,
      status: recipient.status,
      sent_at: recipient.sent_at.to_i,
      delivered_at: recipient.delivered_at&.to_i,
      read_at: recipient.read_at&.to_i,
      failed_at: recipient.failed_at&.to_i
    }
  end
end
