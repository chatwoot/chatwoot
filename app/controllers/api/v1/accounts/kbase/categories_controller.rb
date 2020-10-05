class Api::V1::Accounts::Kbase::CategoriesController < Api::V1::Accounts::Kbase::BaseController
  before_action :fetch_category, except: [:index, :create]

  def index
    @categories = @portal.categories
  end

  def create
    @category = @portal.categories.create!(category_params)
  end

  def update
    @category.update!(category_params)
  end

  def destroy
    @category.destroy
    head :ok
  end

  private

  def fetch_category
    @category = @portal.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(
      :name, :description, :position
    )
  end
end
