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
    interactions = MetaCampaignInteraction
                   .where(account_id: Current.account.id, source_id: params[:id])
                   .includes(:conversation, :message, :inbox)
                   .order(created_at: :desc)

    interactions = interactions.created_between(start_time, end_time) if start_time && end_time

    {
      source_id: params[:id],
      total_interactions: interactions.count,
      unique_conversations: interactions.select(:conversation_id).distinct.count,
      interactions: interactions.limit(100).map do |interaction|
        {
          id: interaction.id,
          conversation_id: interaction.conversation.display_id,
          contact_name: interaction.conversation.contact.name,
          created_at: interaction.created_at,
          metadata: interaction.metadata
        }
      end
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
