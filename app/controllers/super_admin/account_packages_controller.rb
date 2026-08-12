class SuperAdmin::AccountPackagesController < SuperAdmin::ApplicationController
  # Assigns a package to an account for a given period (starts_at -> ends_at).
  # The account is activated/deactivated automatically via the
  # AccountPackage callbacks.
  #
  # The list of packages and the account are supplied to the custom
  # new/edit views so the Super Admin can pick a package and set the period.

  def new
    @account = Account.find(params[:account_id])
    @account_package = AccountPackage.new(account: @account)
    @packages = available_packages
    render :new
  end

  def edit
    @account_package = requested_resource
    @account = @account_package.account
    @packages = available_packages
    render :edit
  end

  def create
    resource = resource_class.new(resource_params)
    authorize_resource(resource)

    notice = resource.save ? translate_with_resource('create.success') : resource.errors.full_messages.first
    redirect_back(fallback_location: [namespace, resource.account], notice: notice)
  end

  def update
    if requested_resource.update(resource_params)
      flash[:notice] = translate_with_resource('update.success')
    else
      flash[:error] = requested_resource.errors.full_messages.join('<br/>')
    end
    redirect_back(fallback_location: [namespace, requested_resource.account])
  end

  def destroy
    if requested_resource.destroy
      flash[:notice] = translate_with_resource('destroy.success')
    else
      flash[:error] = requested_resource.errors.full_messages.join('<br/>')
    end
    redirect_back(fallback_location: [namespace, requested_resource.account])
  end

  private

  def available_packages
    Package.active.order(:name)
  end
end
