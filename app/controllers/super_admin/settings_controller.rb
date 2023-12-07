class SuperAdmin::SettingsController < SuperAdmin::ApplicationController
  def show
  end

  def refresh
    Internal::CheckNewVersionsJob.perform_now
    redirect_to super_admin_instance_status_path, notice: 'Instance status refreshed'
  end
end
