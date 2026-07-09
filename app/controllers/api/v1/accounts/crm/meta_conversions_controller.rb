# Read-only view over the crm_meta_conversion_events ledger for the CRM UI.
#
# index   -> latest Meta conversion per card for a set of visible cards (Lista "Meta"
#            column + card drawer badge). Batched by card_ids so it is only fetched
#            when Meta sync is actually active.
# summary -> aggregate sync health for the dashboard (counts by status/event_type,
#            accepted revenue, last delivery), optionally scoped to a pipeline/window.
#
# The ledger never stores the Meta token, so nothing here can leak a secret.
class Api::V1::Accounts::Crm::MetaConversionsController < Api::V1::Accounts::Crm::BaseController
  def index
    authorize ::Crm::Card

    visible_ids = policy_scope(::Crm::Card).where(id: permitted_card_ids).pluck(:id)
    return render json: { payload: [] } if visible_ids.empty?

    latest_per_card = Crm::MetaConversionEvent
                      .where(account_id: Current.account.id, card_id: visible_ids)
                      .order(created_at: :desc)
                      .group_by(&:card_id)
                      .transform_values(&:first)

    render json: { payload: latest_per_card.values.map { |event| serialize(event) } }
  end

  def summary
    authorize ::Crm::Card, :index?

    scope = filtered_scope
    render json: { payload: {
      by_status: countable_statuses(scope),
      by_event_type: scope.group(:event_type).count,
      accepted_count: scope.accepted.count,
      accepted_value_cents: scope.accepted.where(event_type: 'won').sum(:value_cents),
      last_sent_at: scope.accepted.maximum(:sent_at)
    } }
  end

  private

  def filtered_scope
    scope = Crm::MetaConversionEvent.where(account_id: Current.account.id)
    scope = scope.where(pipeline_id: params[:pipeline_id]) if params[:pipeline_id].present?
    scope = scope.where(created_at: params[:since]..) if params[:since].present?
    scope = scope.where(created_at: ..params[:until]) if params[:until].present?
    scope
  end

  # group(:status) returns the integer enum values; map them back to their names.
  def countable_statuses(scope)
    scope.group(:status).count.transform_keys { |value| Crm::MetaConversionEvent.statuses.key(value) || value }
  end

  def permitted_card_ids
    ids = params[:card_ids].presence || Array(params[:card_id])
    Array(ids).map(&:to_i).reject(&:zero?).uniq
  end

  def serialize(event)
    {
      card_id: event.card_id,
      status: event.status,
      event_type: event.event_type,
      http_code: event.http_code,
      error_message: event.error_message,
      sent_at: event.sent_at,
      event_id: event.event_id
    }
  end
end
