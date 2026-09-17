# Public crawler rules do not need application authentication or callbacks.
class RobotsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def show
    render plain: "User-agent: *\nAllow: /\n", layout: false
  end
end
