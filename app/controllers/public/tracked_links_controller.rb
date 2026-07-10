# rubocop:disable Rails/ApplicationController
class Public::TrackedLinksController < ActionController::Base
  def show
    tracked_link = Ctwa::TrackedLink.find_by(code: params[:code].to_s.upcase)
    return head :not_found if tracked_link.blank?

    # rubocop:disable Rails/SkipsModelValidations
    Ctwa::TrackedLink.increment_counter(:clicks_count, tracked_link.id)
    # rubocop:enable Rails/SkipsModelValidations
    redirect_to tracked_link.wa_link, allow_other_host: true, status: :found
  end
end
# rubocop:enable Rails/ApplicationController
