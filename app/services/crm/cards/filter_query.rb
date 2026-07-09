class Crm::Cards::FilterQuery
  include Crm::Cards::SharedFilters

  FILTER_ATTRIBUTES = %i[pipeline_id inbox_id owner_id priority external_id].freeze
  # List-view-only "Resultado" filter. Uses a DISTINCT param key (`result`) so it
  # never collides with the board filters (the board is strictly open-only and
  # ignores it). `open` is the in-funnel deal status (NOT the conversation
  # status open/pending/resolved); the List status tabs select it explicitly so
  # the default view shows only active deals instead of mixing every status.
  RESULT_STATUSES = %w[open won lost archived].freeze

  # Whitelisted sort columns for the list view. Maps the public `sort` param to a
  # real `crm_cards` column. Anything outside this map falls back to the default
  # ordering (`updated_at desc`), keeping the SQL byte-identical to the board's
  # historical default when no sort is requested.
  SORTABLE = {
    'value_cents' => :value_cents,
    'next_follow_up_at' => :next_follow_up_at,
    'last_activity_at' => :last_activity_at,
    'entered_stage_at' => :entered_stage_at,
    'title' => :title,
    'updated_at' => :updated_at
  }.freeze

  def initialize(scope:, params:)
    @scope = scope
    @params = params
  end

  def perform
    cards = apply_filters(base_scope)
    cards = apply_shared_filters(cards)
    cards = apply_standalone_filter(cards)
    cards = apply_search(apply_follow_up_filter(apply_result_filter(cards)))
    apply_sort(cards)
  end

  private

  def apply_sort(cards)
    column = SORTABLE[@params[:sort].to_s] || :updated_at
    direction = @params[:direction].to_s == 'asc' ? :asc : :desc
    cards.order(column => direction)
  end

  def base_scope
    @scope.includes(:owner, :inbox, :stage, :pipeline, :linked_conversations,
                    contact: { label_taggings: :tag },
                    primary_conversation: [:conversation_participants, { applied_sla: :sla_policy }])
  end

  def apply_filters(cards)
    FILTER_ATTRIBUTES.reduce(cards) { |filtered_cards, attribute| apply_filter(filtered_cards, attribute) }
  end

  # Every new high-value filter is shared with the board so list/board agree.
  def apply_shared_filters(cards)
    cards = apply_stage_ids_filter(cards)
    cards = apply_team_filter(cards)
    cards = apply_value_range_filter(cards)
    cards = apply_stale_filter(cards)
    cards = apply_responsible_filter(cards)
    cards = apply_label_filter(cards)
    cards = apply_campaign_filter(cards)
    apply_ai_pending_filter(cards)
  end

  def apply_standalone_filter(cards)
    return cards.standalone if @params[:standalone].to_s == 'true'
    return cards.linked if @params[:standalone].to_s == 'false'

    cards
  end

  def apply_filter(cards, attribute)
    return cards if @params[attribute].blank?

    cards.where(attribute => @params[attribute])
  end

  def apply_result_filter(cards)
    return cards unless RESULT_STATUSES.include?(@params[:result].to_s)

    cards.where(status: @params[:result])
  end

  def apply_search(cards)
    return cards if @params[:search].blank?

    search_term = ActiveRecord::Base.sanitize_sql_like(@params[:search].strip.downcase)
    cards.where('LOWER(crm_cards.title) LIKE ?', "%#{search_term}%")
  end

  def apply_follow_up_filter(cards)
    case @params[:follow_up_status].presence
    when 'none'
      cards.where(next_follow_up_at: nil)
    when 'pending'
      cards.where.not(next_follow_up_at: nil).where('crm_cards.next_follow_up_at >= ?', Time.current)
    when 'overdue'
      cards.where.not(next_follow_up_at: nil).where('crm_cards.next_follow_up_at < ?', Time.current)
    else
      cards
    end
  end
end
