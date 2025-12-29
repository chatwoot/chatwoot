class Api::V1::Accounts::InboxBotFaqsController < Api::V1::Accounts::BaseController
  skip_before_action :authenticate_user!, only: [:index]
  before_action :validate_bot_token
  before_action :inbox

  def index
    locale = params[:locale] || 'es'
    category_ids = inbox.faq_category_ids

    # Get all visible FAQs from associated categories (including children)
    all_category_ids = get_all_category_ids(category_ids)

    base_query = Current.account.faq_items
                        .visible
                        .where(faq_category_id: all_category_ids)
                        .includes(:faq_category)
                        .order(:position, :created_at)

    # Apply search if provided
    if params[:q].present?
      search_term = "%#{params[:q].downcase}%"
      base_query = base_query.where("LOWER(translations::text) LIKE ?", search_term)
    end

    # Filter by specific category if provided
    if params[:category_id].present?
      base_query = base_query.where(faq_category_id: params[:category_id])
    end

    @faq_items = base_query

    # Build optimized response for bot consumption
    faqs = @faq_items.map do |item|
      {
        id: item.id,
        category_id: item.faq_category_id,
        category: item.faq_category&.name,
        question: item.question(locale),
        answer: item.answer(locale),
        position: item.position
      }
    end

    # Get category tree for context
    categories = Current.account.faq_categories
                        .where(id: all_category_ids)
                        .order(:position, :created_at)
                        .map { |c| { id: c.id, name: c.name, parent_id: c.parent_id } }

    render json: {
      locale: locale,
      inbox_id: inbox.id,
      categories: categories,
      faqs: faqs,
      total: faqs.count,
      last_updated: @faq_items.maximum(:updated_at)&.iso8601
    }
  end

  private

  def inbox
    @inbox ||= Current.account.inboxes.find(params[:inbox_id])
  end

  def validate_bot_token
    # Allow access via bot token or authenticated user
    return if current_user.present?

    bot_token = request.headers['X-Bot-Token'] || params[:bot_token]
    return render_unauthorized unless bot_token.present?

    # Validate against inbox's agent bot or account's bot tokens
    agent_bot = AgentBot.find_by(access_token: bot_token)
    return render_unauthorized unless agent_bot.present?

    # Set account context from bot
    Current.account = agent_bot.account || Account.find(params[:account_id])
  end

  def render_unauthorized
    render json: { error: 'Unauthorized. Valid bot token required.' }, status: :unauthorized
  end

  def get_all_category_ids(parent_ids)
    return [] if parent_ids.blank?

    # Get parent categories and all their children
    children_ids = Current.account.faq_categories
                          .where(parent_id: parent_ids)
                          .pluck(:id)

    (parent_ids + children_ids).uniq
  end
end
