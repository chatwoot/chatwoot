class Platform::Api::V1::AccountsController < PlatformController
  def index
    @resources = @platform_app.platform_app_permissibles
                              .where(permissible_type: 'Account')
                              .includes(:permissible)
                              .map(&:permissible)
  end

  def show; end

  def create
    @resource = Account.create!(account_params)
    update_resource_features
    @resource.save!
    @platform_app.platform_app_permissibles.find_or_create_by(permissible: @resource)
  end

  def update
    @resource.assign_attributes(account_params)
    update_resource_features
    @resource.save!
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
    permitted_params.except(:features, :custom_features)
  end

  def update_resource_features
    return if permitted_params[:features].blank? && permitted_params[:custom_features].blank?

    if permitted_params[:features].present?
      permitted_params[:features].each do |key, value|
        value.present? ? @resource.enable_features(key) : @resource.disable_features(key)
      end
    end

    if permitted_params[:custom_features].present?
      @resource.custom_features = permitted_params[:custom_features]
    end
  end

  def permitted_params
    params.permit(:name, :locale, :domain, :support_email, :status, features: {}, limits: {}, custom_attributes: {}, custom_features: [])
  end
end
