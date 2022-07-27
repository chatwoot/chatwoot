class Platform::Api::V1::AccountsController < PlatformController
  def create
    @resource = Account.new(account_params)
    @resource.save!
    @platform_app.platform_app_permissibles.find_or_create_by(permissible: @resource)
    render json: @resource
  end

  def show
    render json: @resource
  end

  def update
    @resource.update!(account_params)
    render json: @resource
  end

  def destroy
    DeleteObjectJob.perform_later(@resource)
    head :ok
  end

  private

  def set_resource
    @resource = Account.find(params[:id])
  end

  def account_params
    params.permit(:name, :locale)
  end
end
