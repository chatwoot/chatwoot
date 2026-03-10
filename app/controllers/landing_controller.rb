# Public landing page — no authentication required.
# Completely isolated from the dashboard SPA and auth flow.
class LandingController < ActionController::Base
  layout 'landing'

  def index; end
end
