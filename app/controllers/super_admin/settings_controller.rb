class SuperAdmin::SettingsController < SuperAdmin::ApplicationController
  def show; end

  # Also the Stripe portal's return URL, so a failed sync must say so instead of claiming a refresh.
  def refresh
    if Internal::CheckNewVersionsJob.perform_now(refresh_billing: true)
      redirect_to super_admin_settings_path, notice: I18n.t('super_admin.settings.refresh_succeeded')
    else
      redirect_to super_admin_settings_path, alert: I18n.t('super_admin.settings.refresh_failed')
    end
  end
end
