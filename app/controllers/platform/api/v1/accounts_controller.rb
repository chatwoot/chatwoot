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
    if permitted_params[:features].present?
      feature_flags = permitted_params[:features].select { |key, value| value }.keys.map { |name|:"feature_#{name}".to_sym }
      permitted_params.except(:features).merge(selected_feature_flags: feature_flags)
    else
      permitted_params
    end
  end

  def permitted_params
    params.permit(:name, :locale, :domain, :support_email, :status, features: {}, limits: {}, custom_attributes: {})
  end
end
