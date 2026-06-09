class SuperAdmin::PlatformBannersController < SuperAdmin::ApplicationController
  before_action :ensure_chatwoot_cloud

  private

  def ensure_chatwoot_cloud
    raise ActionController::RoutingError, 'Not Found' unless ChatwootApp.chatwoot_cloud?
  end
end
