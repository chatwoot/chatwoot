class Api::V1::Accounts::FaqItemsController < Api::V1::Accounts::BaseController
  before_action :faq_item, only: %i[show update destroy toggle_visibility move]
  before_action :check_authorization
  before_action :check_rate_limit, only: %i[create]

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 50

    base_query = Current.account.faq_items.includes(:faq_category)

    # Filter by category if provided
    base_query = base_query.for_category(params[:category_id]) if params[:category_id].present?

    # Apply search if query parameter is present
    # Order by created_at ascending (oldest first)
    @faq_items = if params[:q].present?
                   # Search in translations JSONB
                   search_term = "%#{params[:q].downcase}%"
                   base_query.where(
                     "LOWER(translations::text) LIKE ?", search_term
                   ).order(created_at: :asc).page(page).per(per_page)
                 else
                   base_query.order(created_at: :asc).page(page).per(per_page)
                 end

    @total_count = @faq_items.total_count
    @total_pages = (@total_count.to_f / per_page.to_i).ceil
    @current_page = page.to_i
  end

  def show; end

  def create
    @faq_item = Current.account.faq_items.create!(
      faq_item_params.merge(created_by: current_user)
    )
    render :show, status: :created
  end

  def update
    @faq_item.update!(faq_item_params.merge(updated_by: current_user))
    render :show
  end

  def destroy
    @faq_item.destroy!
    head :ok
  end

  def toggle_visibility
    @faq_item.update!(is_visible: !@faq_item.is_visible, updated_by: current_user)
    render :show
  end

  def move
    direction = params[:direction]
    return render json: { error: "Invalid direction" }, status: :unprocessable_entity unless %w[up down].include?(direction)

    category_items = Current.account.faq_items.where(faq_category_id: @faq_item.faq_category_id).ordered.to_a
    current_index = category_items.index(@faq_item)

    new_index = direction == "up" ? current_index - 1 : current_index + 1
    return render json: { error: "Cannot move in that direction" }, status: :unprocessable_entity if new_index.negative? || new_index >= category_items.length

    # Swap positions
    other_item = category_items[new_index]
    current_position = @faq_item.position
    @faq_item.update!(position: other_item.position, updated_by: current_user)
    other_item.update!(position: current_position)

    # Return both swapped items to avoid page refresh
    render json: {
      items: [
        render_faq_item(@faq_item),
        render_faq_item(other_item)
      ]
    }
  end

  def bulk_delete
    ids = params[:ids]
    return render json: { error: "No FAQ IDs provided" }, status: :unprocessable_entity unless ids.present?

    deleted_count = Current.account.faq_items.where(id: ids).destroy_all.count
    render json: { deleted_count: deleted_count }
  end

  private

  def faq_item
    @faq_item ||= Current.account.faq_items.find(params[:id])
  end

  def faq_item_params
    permitted = params.require(:faq_item).permit(:faq_category_id, :position, :is_visible)
    # Permit nested translations hash with dynamic locale keys (es, en, etc.)
    # Only allow question and answer fields per locale for security
    if params[:faq_item][:translations].present?
      permitted[:translations] = sanitize_translations(params[:faq_item][:translations])
    end
    permitted
  end

  def sanitize_translations(translations_params)
    translations_params.to_unsafe_h.each_with_object({}) do |(locale, content), result|
      next unless content.is_a?(Hash)

      result[locale] = content.slice('question', 'answer').transform_values(&:to_s)
    end
  end

  def render_faq_item(item)
    {
      id: item.id,
      faq_category_id: item.faq_category_id,
      position: item.position,
      is_visible: item.is_visible,
      translations: item.translations,
      primary_question: item.question('es'),
      primary_answer: item.answer('es'),
      created_at: item.created_at,
      updated_at: item.updated_at
    }
  end

  def check_rate_limit
    unless Faqs::RateLimiterService.acquire_lock(Current.account.id, :create, 'item')
      lock_info = Faqs::RateLimiterService.lock_info(Current.account.id, :create, 'item')
      remaining = lock_info&.dig(:remaining_seconds) || 3

      render json: {
        error: "Rate limit exceeded. Please wait #{remaining} seconds before trying again.",
        retry_after: remaining
      }, status: :too_many_requests
    end
  end
end
