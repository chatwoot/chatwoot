class Api::V2::Accounts::MetaCampaignReportsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    @campaigns = fetch_campaigns_with_stats
    render json: format_campaigns_response(@campaigns)
  end

  def show
    @campaign_stats = fetch_campaign_details
    render json: @campaign_stats
  end

  def summary
    @summary = build_summary
    render json: @summary
  end

  private

  def check_authorization
    authorize :report, :view?
  end

  def fetch_campaigns_with_stats
    inbox_id = params[:inbox_id]
    MetaCampaignInteraction.stats_by_campaign(Current.account.id, inbox_id, start_time, end_time)
  end

  def fetch_campaign_details
    interactions_scope = build_interactions_scope
    total_count = interactions_scope.count
    paginated_interactions = paginate_interactions(interactions_scope)

    {
      source_id: params[:id],
      total_interactions: total_count,
      unique_conversations: interactions_scope.select(:conversation_id).distinct.count,
      interactions: format_interactions(paginated_interactions),
      meta: build_pagination_meta(total_count)
    }
  end

  def build_interactions_scope
    scope = MetaCampaignInteraction
            .where(account_id: Current.account.id, source_id: params[:id])
            .includes(:conversation, :message, :inbox)
            .order(created_at: :desc)
    scope = scope.created_between(start_time, end_time) if start_time && end_time
    scope
  end

  def paginate_interactions(scope)
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 25
    offset = (page - 1) * per_page
    scope.limit(per_page).offset(offset)
  end

  def format_interactions(interactions)
    interactions.map do |interaction|
      {
        id: interaction.id,
        conversation_id: interaction.conversation.display_id,
        contact_name: interaction.conversation.contact.name,
        created_at: interaction.created_at,
        metadata: interaction.metadata
      }
    end
  end

  def build_pagination_meta(total_count)
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 25
    {
      current_page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: (total_count.to_f / per_page).ceil
    }
  end

  def build_summary
    scope = MetaCampaignInteraction.where(account_id: Current.account.id)
    scope = scope.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?
    scope = scope.created_between(start_time, end_time) if start_time && end_time

    {
      total_campaigns: scope.select(:source_id).distinct.count,
      total_interactions: scope.count,
      unique_conversations: scope.select(:conversation_id).distinct.count,
      interactions_by_type: scope.group(:source_type).count,
      by_inbox: scope.joins(:inbox).group('inboxes.name').count
    }
  end

  def format_campaigns_response(campaigns)
    campaigns.map do |campaign|
      {
        source_id: campaign.source_id,
        source_type: campaign.source_type,
        interaction_count: campaign.interaction_count,
        first_interaction: campaign.first_interaction,
        last_interaction: campaign.last_interaction,
        metadata: campaign.campaign_metadata
      }
    end
  end

  def start_time
    @start_time ||= params[:since].present? ? Time.zone.at(params[:since].to_i) : nil
  end

  def end_time
    @end_time ||= params[:until].present? ? Time.zone.at(params[:until].to_i) : nil
  end
end
