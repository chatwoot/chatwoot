class SuperAdmin::AccountsController < SuperAdmin::ApplicationController
  # Overwrite any of the RESTful controller actions to implement custom behavior
  # For example, you may want to send an email after a foo is updated.
  #
  # def update
  #   super
  #   send_foo_updated_email(requested_resource)
  # end

  # Override this method to specify custom lookup behavior.
  # This will be used to set the resource for the `show`, `edit`, and `update`
  # actions.
  #
  # def find_resource(param)
  #   Foo.find_by!(slug: param)
  # end

  # The result of this lookup will be available as `requested_resource`

  # Override this if you have certain roles that require a subset
  # this will be used to set the records shown on the `index` action.
  #
  # def scoped_resource
  #   if current_user.super_admin?
  #     resource_class
  #   else
  #     resource_class.with_less_stuff
  #   end
  # end

  # Override `resource_params` if you want to transform the submitted
  # data before it's persisted. For example, the following would turn all
  # empty values into nil values. It uses other APIs such as `resource_class`
  # and `dashboard`:
  #
  def resource_params
    permitted_params = super
    permitted_params[:limits] = permitted_params[:limits].to_h.compact
    permitted_params[:selected_feature_flags] = params[:enabled_features].keys.map(&:to_sym) if params[:enabled_features].present?
    permitted_params
  end

  # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
  # for more information

  def seed
    Internal::SeedAccountJob.perform_later(requested_resource)
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account seeding triggered')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def reset_cache
    requested_resource.reset_cache_keys
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Cache keys cleared')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  def destroy
    account = Account.find(params[:id])

    DeleteObjectJob.perform_later(account) if account.present?
    # rubocop:disable Rails/I18nLocaleTexts
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account deletion is in progress.')
    # rubocop:enable Rails/I18nLocaleTexts
  end

  # ── Billing Admin Actions ──────────────────────────────────────
  # rubocop:disable Rails/I18nLocaleTexts

  def grant_trial
    days = (params[:days].presence || 14).to_i
    plan_key = params[:plan_key].presence || 'pro_monthly'
    requested_resource.grant_trial!(days: days, plan_key: plan_key)
    redirect_back(fallback_location: [namespace, requested_resource], notice: "Trial granted for #{days} days on #{plan_key}")
  rescue StandardError => e
    redirect_back(fallback_location: [namespace, requested_resource], alert: e.message)
  end

  def extend_trial
    days = (params[:days].presence || 14).to_i
    requested_resource.extend_trial!(days: days)
    redirect_back(fallback_location: [namespace, requested_resource], notice: "Trial extended by #{days} days")
  rescue StandardError => e
    redirect_back(fallback_location: [namespace, requested_resource], alert: e.message)
  end

  def grant_complimentary
    plan_key = params[:plan_key].presence || 'pro_monthly'
    requested_resource.grant_complimentary!(plan_key: plan_key)
    redirect_back(fallback_location: [namespace, requested_resource], notice: "Complimentary #{plan_key} subscription granted")
  rescue StandardError => e
    redirect_back(fallback_location: [namespace, requested_resource], alert: e.message)
  end

  def override_plan
    requested_resource.override_plan!(params[:plan_key])
    redirect_back(fallback_location: [namespace, requested_resource], notice: "Plan overridden to #{params[:plan_key]}")
  rescue StandardError => e
    redirect_back(fallback_location: [namespace, requested_resource], alert: e.message)
  end

  def add_bonus_credits
    amount = (params[:amount].presence || 1000).to_i
    requested_resource.add_bonus_credits!(amount)
    redirect_back(fallback_location: [namespace, requested_resource], notice: "Added #{amount} bonus AI credits")
  rescue StandardError => e
    redirect_back(fallback_location: [namespace, requested_resource], alert: e.message)
  end

  def reset_usage
    requested_resource.reset_usage!
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Usage counters reset to zero')
  rescue StandardError => e
    redirect_back(fallback_location: [namespace, requested_resource], alert: e.message)
  end

  def cancel_subscription
    requested_resource.cancel_subscription!
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Subscription will cancel at period end')
  rescue StandardError => e
    redirect_back(fallback_location: [namespace, requested_resource], alert: e.message)
  end

  def suspend
    requested_resource.suspend_for_nonpayment!
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account suspended for nonpayment')
  rescue StandardError => e
    redirect_back(fallback_location: [namespace, requested_resource], alert: e.message)
  end

  def reactivate
    requested_resource.reactivate_after_payment!
    redirect_back(fallback_location: [namespace, requested_resource], notice: 'Account reactivated')
  rescue StandardError => e
    redirect_back(fallback_location: [namespace, requested_resource], alert: e.message)
  end

  # rubocop:enable Rails/I18nLocaleTexts
end

SuperAdmin::AccountsController.prepend_mod_with('SuperAdmin::AccountsController')
