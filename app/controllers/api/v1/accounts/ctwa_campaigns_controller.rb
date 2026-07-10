# CTWA campaign options for the Conversations and Kanban campaign filter pickers.
# Deliberately OUTSIDE the CRM gate (no Crm::BaseController / ensure_crm_enabled):
# the Conversations filter must work even when the CRM module is disabled.
# Agent-level access via the standard conversation policy (index is open to any
# account member); the payload is aggregated ad metadata only, no message content.
class Api::V1::Accounts::CtwaCampaignsController < Api::V1::Accounts::BaseController
  # Aggregates every campaign touch (additional_attributes['campaign_touches'])
  # of the account's conversations per ad: the most recent non-blank headline wins,
  # count is distinct conversations, last_touch_at is the latest touch. Dataset is
  # small (touches are capped per conversation), so plain LATERAL SQL keeps it simple.
  AGGREGATION_SQL = <<~SQL.squish.freeze
    SELECT
      elem ->> 'source_id' AS source_id,
      (ARRAY_AGG(elem ->> 'headline' ORDER BY elem ->> 'touched_at' DESC NULLS LAST)
        FILTER (WHERE COALESCE(elem ->> 'headline', '') <> ''))[1] AS headline,
      (ARRAY_AGG(elem ->> 'source' ORDER BY elem ->> 'touched_at' DESC NULLS LAST))[1] AS source,
      COUNT(DISTINCT conversations.id) AS conversations_count,
      MAX(elem ->> 'touched_at') AS last_touch_at
    FROM conversations
    CROSS JOIN LATERAL jsonb_array_elements(conversations.additional_attributes -> 'campaign_touches') AS elem
    WHERE conversations.account_id = ?
      AND conversations.id IN (%<visible_ids>s)
      AND jsonb_typeof(conversations.additional_attributes -> 'campaign_touches') = 'array'
      AND COALESCE(elem ->> 'source_id', '') <> ''
    GROUP BY elem ->> 'source_id'
    ORDER BY conversations_count DESC, source_id ASC
  SQL

  def index
    authorize ::Conversation, :index?

    render json: { payload: campaign_options }
  end

  private

  # Aggregation is scoped to the conversations the requesting agent can actually see
  # (same PermissionFilterService the ConversationFinder uses) — otherwise campaign
  # metadata from inboxes outside the agent's visibility would leak into the picker.
  def visible_conversations
    Conversations::PermissionFilterService.new(
      Current.account.conversations,
      Current.user,
      Current.account
    ).perform
  end

  def campaign_options
    aggregation = format(AGGREGATION_SQL, visible_ids: visible_conversations.reorder(nil).select(:id).to_sql)
    sql = ActiveRecord::Base.sanitize_sql_array([aggregation, Current.account.id])
    ActiveRecord::Base.connection.select_all(sql).map do |row|
      {
        source_id: row['source_id'],
        headline: row['headline'],
        count: row['conversations_count'].to_i,
        last_touch_at: row['last_touch_at']
      }
    end
  end
end
