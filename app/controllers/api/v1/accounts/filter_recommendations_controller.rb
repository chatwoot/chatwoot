class Api::V1::Accounts::FilterRecommendationsController < Api::V1::Accounts::BaseController
  QUERY_LENGTH = (3..200)
  FILTER_TYPES = %w[conversation contact automation].freeze

  before_action :ensure_recommendations_available

  def create
    query = params.require(:query).to_s.strip
    return render_could_not_create_error('Query must be between 3 and 200 characters') unless QUERY_LENGTH.cover?(query.length)

    filter_type = params.require(:filter_type)
    return render_could_not_create_error('Filter type must be conversation, contact or automation') unless FILTER_TYPES.include?(filter_type)
    return render_could_not_create_error('Attribute keys must be a list of condition keys') if filter_type == 'automation' && attribute_keys.nil?

    recommendations = Captain::FilterRecommendationService.new(account: Current.account, field_set: field_set(filter_type), query: query).perform
    render json: { payload: recommendations }
  end

  private

  def field_set(filter_type)
    case filter_type
    when 'conversation' then Captain::ConversationFilterFields.new(account: Current.account, user: Current.user)
    when 'contact' then Captain::ContactFilterFields.new(account: Current.account, user: Current.user)
    when 'automation' then Captain::AutomationFilterFields.new(account: Current.account, user: Current.user, attribute_keys: attribute_keys)
    end
  end

  # The condition keys the automation rule's event offers.
  def attribute_keys
    keys = params[:attribute_keys]
    keys if keys.is_a?(Array) && keys.present? && keys.all?(String)
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
