class Api::V1::Accounts::ProductsController < Api::V1::Accounts::BaseController
  before_action :fetch_product, except: [:index, :create]
  before_action :check_authorization

  def index
    @products = policy_scope(Current.account.products)
  end

  def show; end

  def create
    @product = Current.account.products.create!(product_params)
    process_attached_image
  end

  def update
    @product.update!(product_params)
    process_attached_image if params[:blob_id].present?
  end

  def destroy
    @product.destroy!
    head :ok
  end

  private

  def fetch_product
    @product = Current.account.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:title_en, :title_ar, :description_en, :description_ar, :price)
  end

  def process_attached_image
    blob_id = params[:blob_id]
    return if blob_id.blank?

    blob = ActiveStorage::Blob.find_signed(blob_id)
    @product.image.attach(blob) if blob
  end
end
