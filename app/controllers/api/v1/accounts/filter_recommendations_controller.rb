class Api::V1::Accounts::FilterRecommendationsController < Api::V1::Accounts::BaseController
  QUERY_LENGTH = (3..200)
  FILTER_TYPES = %w[conversation contact automation].freeze

  before_action :ensure_recommendations_available

  def create
    query = params.require(:query).to_s.strip
    return render_could_not_create_error('Query must be between 3 and 200 characters') unless QUERY_LENGTH.cover?(query.length)

    filter_type = params.require(:filter_type)
    return render_could_not_create_error('Filter type must be conversation, contact or automation') unless FILTER_TYPES.include?(filter_type)
    return render_automation_recommendations(query) if filter_type == 'automation'

    field_set_class = filter_type == 'contact' ? Captain::ContactFilterFields : Captain::ConversationFilterFields
    render json: { payload: recommend(field_set_class.new(account: Current.account, user: Current.user), query) }
  end

  private

  # With `events`, the rule's event may still change: Jev picks one from its name and description, and the
  # conditions come from that event's keys. When Jev picks none, they come from `attribute_keys`, the keys of
  # the rule's current event. Without `events`, the event is already chosen.
  # With `action_names`, the response also recommends actions from the ones the form offers.
  def render_automation_recommendations(query)
    if params.key?(:events)
      events = event_condition_keys
      return render_could_not_create_error('Events must map event names to lists of condition keys') unless events
    elsif !string_list?(params[:attribute_keys])
      return render_could_not_create_error('Attribute keys must be a list of condition keys')
    end

    event_name = recommend_event(query, events) if events
    render json: { payload: automation_conditions(query, events, event_name), event_name: event_name, actions: automation_actions(query) }
  end

  def recommend_event(query, events)
    Captain::AutomationEventRecommendation.new(account: Current.account, query: query, events: events.keys).perform
  end

  def automation_conditions(query, events, event_name)
    attribute_keys = event_name ? events[event_name] : params[:attribute_keys]
    recommend(automation_fields(attribute_keys), query) if string_list?(attribute_keys)
  end

  def automation_actions(query)
    return unless string_list?(params[:action_names])

    action_fields = Captain::AutomationActionFields.new(account: Current.account, user: Current.user, action_names: params[:action_names])
    recommend(action_fields, query)
  end

  def recommend(field_set, query)
    Captain::FilterRecommendationService.new(account: Current.account, field_set: field_set, query: query).perform
  end

  def automation_fields(attribute_keys)
    Captain::AutomationFilterFields.new(account: Current.account, user: Current.user, attribute_keys: attribute_keys)
  end

  # The events the automation form offers, each with the condition keys it allows.
  def event_condition_keys
    events = params.permit(events: {})[:events]&.to_h
    events if events.present? && events.values.all? { |keys| string_list?(keys) }
  end

  def string_list?(value)
    value.is_a?(Array) && value.present? && value.all?(String)
  end

  def ensure_recommendations_available
    raise Pundit::NotAuthorizedError unless recommendations_available?
  end

  # Recommendations are a paid feature. Enterprise decides which accounts are on a paid plan.
  def recommendations_available?
    false
  end
end

Api::V1::Accounts::FilterRecommendationsController.prepend_mod_with('Api::V1::Accounts::FilterRecommendationsController')
