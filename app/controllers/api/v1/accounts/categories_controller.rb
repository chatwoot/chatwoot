class Api::V1::Accounts::CategoriesController < Api::V1::Accounts::BaseController
  before_action :portal
  before_action :check_authorization
  before_action :fetch_category, except: [:index, :create]
  before_action :set_current_page, only: [:index]

  def index
    @categories = @portal.categories.search(params)
  end

  def create
    @category = @portal.categories.create!(category_params)
    @category.related_categories << related_categories_records
    render json: { error: @category.errors.messages }, status: :unprocessable_entity and return unless @category.valid?

    @category.save!
  end

  def show; end

  def update
    @category.update!(category_params)
    @category.related_categories = related_categories_records if related_categories_records.any?
    render json: { error: @category.errors.messages }, status: :unprocessable_entity and return unless @category.valid?

    @category.save!
  end

  def destroy
    @category.destroy!
    head :ok
  end

  private

  def fetch_category
    @category = @portal.categories.find(params[:id])
  end

  def portal
    @portal ||= Current.account.portals.find_by(slug: params[:portal_id])
  end

  def related_categories_records
    @portal.categories.where(id: params[:category][:related_category_ids])
  end

  def category_params
    params.require(:category).permit(
      :name, :description, :position, :slug, :locale, :parent_category_id, :associated_category_id
    )
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
