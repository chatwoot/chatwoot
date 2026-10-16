# Public crawler rules do not need application authentication or callbacks.
class RobotsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def show
    # Widget loads create contacts before rendering, so preserve their crawl exclusion.
    render plain: "User-agent: *\nDisallow: /widget\n", layout: false
  end
end
