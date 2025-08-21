class Api::V1::Accounts::LibraryResourcesController < Api::V1::Accounts::BaseController
  before_action :fetch_resource, except: [:index, :create]
  before_action :set_current_page, only: [:index]

  def index
    @library_resources = Current.account.library_resources.order(updated_at: :desc).page(@current_page)
  end

  def show; end

  def create
    @library_resource = Current.account.library_resources.create!(resource_params)
    render json: { error: @library_resource.errors.messages }, status: :unprocessable_entity and return unless @library_resource.valid?
  end

  def update
    @library_resource.update!(resource_params) if params[:library_resource].present?
    render json: { error: @library_resource.errors.messages }, status: :unprocessable_entity and return unless @library_resource.valid?
  end

  def destroy
    @library_resource.destroy!
    head :ok
  end

  private

  def fetch_resource
    @library_resource = Current.account.library_resources.find(params[:id])
  end

  def resource_params
    params.require(:library_resource).permit(:title, :description, :content)
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
