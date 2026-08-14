class SuperAdmin::AccountAddonsController < SuperAdmin::ApplicationController
  # Activates an Addon (from the catalog) for an account, scoped to the account's
  # current base package. The period is defined either as a fixed length
  # (1/3/6 months, or until the end of the base package) or a custom
  # start/end date, and is resolved to starts_at/ends_at by the model
  # (AccountAddon#resolve_period).
  #
  # The account and the available (active) add-ons are supplied to the custom
  # new/edit views so the Super Admin can pick an add-on and set its period.

  def new
    @account = Account.find(params[:account_id])
    @account_addon = AccountAddon.new(account: @account)
    @account_package = @account.current_account_package if @account.respond_to?(:current_account_package)
    @addons = available_addons
    render :new
  end

  def edit
    @account_addon = requested_resource
    @account = @account_addon.account
    @account_package = @account.current_account_package if @account.respond_to?(:current_account_package)
    @addons = available_addons
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

  def available_addons
    Addon.active.order(:name)
  end

  # The form submits the virtual date inputs (start_date/end_date) plus the
  # duration mode; the column values (starts_at/ends_at) are derived by the
  # model. Blank duration_months must not reach the numericality validation.
  def resource_params
    params.require(resource_class.model_name.param_key)
          .permit(:account_id, :addon_id, :start_date, :duration_type, :duration_months, :end_date)
          .transform_values(&:presence)
  end
end
