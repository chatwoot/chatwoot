class Platform::Api::V1::AccountsController < PlatformController
  def create
    @resource = Account.new(account_params)
    @resource.save!
    @platform_app.platform_app_permissibles.find_or_create_by(permissible: @resource)
  end

  def show; end

  def update
    @resource.update!(account_params)
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
    if permitted_params[:enabled_features]
      return permitted_params.except(:enabled_features).merge(selected_feature_flags: permitted_params[:enabled_features].map(&:to_sym))
    end

    permitted_params
  end

  def permitted_params
    params.permit(:name, :locale, enabled_features: [], limits: {})
  end
end
