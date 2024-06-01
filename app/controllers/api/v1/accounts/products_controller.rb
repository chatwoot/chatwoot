class Api::V1::Accounts::ProductsController < Api::V1::Accounts::BaseController
  sort_on :name, type: :string
  sort_on :short_name, type: :string
  sort_on :price, type: :float

  RESULTS_PER_PAGE = 15
  before_action :set_current_page, only: [:index, :search]
  before_action :fetch_product, only: [:show, :update, :destroy]

  def index
    @products = Current.account.products
    render json: {
      meta: { count: @products.count, current_page: @current_page },
      payload: @products.to_json
    }
  end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    @products = Current.account.products.where(
      'products.name ILIKE :search OR products.short_name ILIKE :search',
      search: "%#{params[:q].strip}%"
    )
    render json: {
      meta: { count: @products.count, current_page: @current_page },
      payload: @products.to_json
    }
  end

  def show
    render json: @product.to_json
  end

  def create
    @product = Current.account.products.new(permitted_params)
    @product.save!
  end

  def update
    @product.assign_attributes(product_update_params)
    @product.save!
    render json: @product.to_json
  end

  def destroy
    @product.destroy!
    head :ok
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  private

  def fetch_product
    @product = Current.account.products.find(params[:id])
  end

  def permitted_params
    params.permit(:name, :short_name, :price, :disabled, custom_attributes: {})
  end

  def product_custom_attributes
    return @product.custom_attributes.merge(permitted_params[:custom_attributes]) if permitted_params[:custom_attributes]

    @product.custom_attributes
  end

  def product_update_params
    # we want the merged custom attributes not the original one
    permitted_params.except(:custom_attributes).merge({ custom_attributes: product_custom_attributes })
  end
end
