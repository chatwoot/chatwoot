module Enterprise::SuperAdmin::AccountsController
  def update
    # Handle manually managed features from form submission
    if params[:account] && params[:account][:manually_managed_features].present?
      # Update using the service - it will handle array conversion and validation
      service = ::Internal::Accounts::InternalAttributesService.new(requested_resource)
      service.manually_managed_features = params[:account][:manually_managed_features]

      # Remove the manually_managed_features from params to prevent ActiveModel::UnknownAttributeError
      params[:account].delete(:manually_managed_features)
    end

    super
  end
end
