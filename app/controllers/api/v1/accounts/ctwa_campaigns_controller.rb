# CTWA campaign options for the Conversations and Kanban campaign filter pickers.
# Deliberately OUTSIDE the CRM gate (no Crm::BaseController / ensure_crm_enabled):
# the Conversations filter must work even when the CRM module is disabled.
# Agent-level access via the standard conversation policy (index is open to any
# account member); the payload is aggregated ad metadata only, no message content.
class Api::V1::Accounts::CtwaCampaignsController < Api::V1::Accounts::BaseController
  DEFAULT_RANGE_DAYS = 30
  MAX_RANGE_DAYS = 366

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

  ORIGIN_METRICS_SQL = <<~SQL.squish.freeze
    WITH visible_conversation_ids AS (%<visible_ids>s),
    eligible_cards AS (
      SELECT
        crm_cards.id AS card_id,
        crm_cards.account_id AS account_id,
        crm_cards.conversation_id AS conversation_id,
        crm_cards.currency AS currency,
        crm_cards.value_cents AS value_cents
      FROM crm_cards
      WHERE %<card_filters>s
    ),
    candidate_origins AS (
      SELECT
        eligible_cards.card_id,
        eligible_cards.currency,
        eligible_cards.value_cents,
        conversations.id AS conversation_id,
        conversations.additional_attributes -> 'campaign' AS campaign,
        NULLIF(conversations.additional_attributes -> 'campaign' ->> 'touched_at', '') AS touched_at
      FROM eligible_cards
      INNER JOIN conversations ON conversations.id = eligible_cards.conversation_id
        AND conversations.account_id = eligible_cards.account_id
      INNER JOIN visible_conversation_ids ON visible_conversation_ids.id = conversations.id
      WHERE jsonb_exists(conversations.additional_attributes, 'campaign')
      UNION ALL
      SELECT
        eligible_cards.card_id,
        eligible_cards.currency,
        eligible_cards.value_cents,
        conversations.id AS conversation_id,
        conversations.additional_attributes -> 'campaign' AS campaign,
        NULLIF(conversations.additional_attributes -> 'campaign' ->> 'touched_at', '') AS touched_at
      FROM eligible_cards
      INNER JOIN crm_card_conversations ON crm_card_conversations.card_id = eligible_cards.card_id
        AND crm_card_conversations.account_id = eligible_cards.account_id
      INNER JOIN conversations ON conversations.id = crm_card_conversations.conversation_id
        AND conversations.account_id = eligible_cards.account_id
      INNER JOIN visible_conversation_ids ON visible_conversation_ids.id = conversations.id
      WHERE jsonb_exists(conversations.additional_attributes, 'campaign')
    ),
    canonical_cards AS (
      SELECT DISTINCT ON (card_id)
        COALESCE(NULLIF(candidate_origins.campaign ->> 'source', ''), 'meta_ctwa') AS source,
        candidate_origins.card_id,
        candidate_origins.currency,
        candidate_origins.value_cents
      FROM candidate_origins
      ORDER BY card_id, touched_at ASC NULLS FIRST, conversation_id ASC
    ),
    counts AS (
      SELECT source, COUNT(*) AS won_count
      FROM canonical_cards
      GROUP BY source
    ),
    currency_totals AS (
      SELECT source, currency, SUM(value_cents) AS value_cents
      FROM canonical_cards
      GROUP BY source, currency
    )
    SELECT
      counts.source,
      counts.won_count,
      COALESCE(
        JSONB_AGG(
          JSONB_BUILD_OBJECT('currency', currency_totals.currency, 'value_cents', currency_totals.value_cents)
          ORDER BY currency_totals.currency
        ) FILTER (WHERE currency_totals.currency IS NOT NULL),
        '[]'::jsonb
      ) AS won_value_by_currency
    FROM counts
    LEFT JOIN currency_totals ON currency_totals.source = counts.source
    GROUP BY counts.source, counts.won_count
  SQL

  def index
    authorize ::Conversation, :index?
    authorize %i[crm report], :view? if include_origin_metrics?

    response = { payload: campaign_options }
    response[:origin_metrics] = origin_metrics if include_origin_metrics?
    render json: response
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
        source: row['source'],
        headline: row['headline'],
        count: row['conversations_count'].to_i,
        last_touch_at: row['last_touch_at']
      }
    end
  end

  def include_origin_metrics?
    ActiveModel::Type::Boolean.new.cast(params[:include_origin_metrics])
  end

  def origin_metrics
    card_filters, binds = origin_metric_card_filters
    aggregation = format(
      ORIGIN_METRICS_SQL,
      visible_ids: visible_conversations.reorder(nil).select(:id).to_sql,
      card_filters: card_filters.join(' AND ')
    )
    sql = ActiveRecord::Base.sanitize_sql_array([aggregation, *binds])
    ActiveRecord::Base.connection.select_all(sql).map do |row|
      {
        source: row['source'],
        won_count: row['won_count'].to_i,
        won_value_by_currency: parsed_jsonb(row['won_value_by_currency'])
      }
    end
  end

  def origin_metric_card_filters
    filters = [
      'crm_cards.account_id = ?',
      'crm_cards.status = ?',
      'crm_cards.closed_at BETWEEN ? AND ?'
    ]
    binds = [Current.account.id, Crm::Card.statuses[:won], since_time, until_time]

    if params[:pipeline_id].present?
      filters << 'crm_cards.pipeline_id = ?'
      binds << params[:pipeline_id]
    end

    [filters, binds]
  end

  def since_time
    @since_time ||= parse_time(params[:since]) || DEFAULT_RANGE_DAYS.days.ago.beginning_of_day
  end

  def until_time
    @until_time ||= begin
      parsed = parse_time(params[:until]) || Time.current
      max_until = since_time + MAX_RANGE_DAYS.days
      [parsed, max_until].min
    end
  end

  def parse_time(value)
    return if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def parsed_jsonb(value)
    return value if value.is_a?(Array)

    JSON.parse(value.to_s)
  end
end
