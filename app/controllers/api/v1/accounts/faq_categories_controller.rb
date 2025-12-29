class Api::V1::Accounts::FaqCategoriesController < Api::V1::Accounts::BaseController
  before_action :faq_category, only: %i[show update destroy toggle_visibility move]
  before_action :check_authorization
  before_action :check_rate_limit, only: %i[create]

  def index
    @faq_categories = Current.account.faq_categories
                             .roots
                             .includes(:children, :faq_items)
                             .ordered
  end

  def tree
    page = params[:page] || 1
    per_page = params[:per_page] || 5

    base_query = Current.account.faq_categories
                        .roots
                        .includes(children: [:children, :faq_items])

    # Apply search if query parameter is present
    if params[:q].present?
      search_term = "%#{params[:q].downcase}%"
      # Search in category names and FAQ translations
      category_ids = Current.account.faq_categories
                           .where("LOWER(name) LIKE ?", search_term)
                           .pluck(:id)
      faq_category_ids = Current.account.faq_items
                                .where("LOWER(translations::text) LIKE ?", search_term)
                                .pluck(:faq_category_id)
                                .compact
      all_ids = (category_ids + faq_category_ids).uniq

      # Get root categories that match or have matching children/FAQs
      root_ids = Current.account.faq_categories
                        .where(id: all_ids)
                        .pluck(:id, :parent_id)
                        .map { |id, parent_id| parent_id || id }
                        .uniq

      base_query = base_query.where(id: root_ids)
    end

    @faq_categories = base_query.order(created_at: :asc).page(page).per(per_page)
    @total_count = @faq_categories.total_count
    @total_pages = (@total_count.to_f / per_page.to_i).ceil
    @current_page = page.to_i
  end

  def show; end

  def create
    @faq_category = Current.account.faq_categories.create!(
      faq_category_params.merge(created_by: current_user)
    )
    render :show, status: :created
  end

  def update
    @faq_category.update!(faq_category_params.merge(updated_by: current_user))
    render :show
  end

  def destroy
    @faq_category.destroy!
    head :ok
  end

  def toggle_visibility
    @faq_category.update!(is_visible: !@faq_category.is_visible, updated_by: current_user)
    render :show
  end

  def move
    new_parent_id = params[:parent_id]
    new_position = params[:position]&.to_i || 0

    @faq_category.update!(
      parent_id: new_parent_id.presence,
      position: new_position,
      updated_by: current_user
    )
    render :show
  end

  private

  def faq_category
    @faq_category ||= Current.account.faq_categories.find(params[:id])
  end

  def faq_category_params
    params.require(:faq_category).permit(:name, :description, :parent_id, :position, :is_visible)
  end

  def check_rate_limit
    unless Faqs::RateLimiterService.acquire_lock(Current.account.id, :create, 'category')
      lock_info = Faqs::RateLimiterService.lock_info(Current.account.id, :create, 'category')
      remaining = lock_info&.dig(:remaining_seconds) || 3

      render json: {
        error: "Rate limit exceeded. Please wait #{remaining} seconds before trying again.",
        retry_after: remaining
      }, status: :too_many_requests
    end
  end
end
