require 'cgi'

# rubocop:disable Rails/ApplicationController
class Public::TrackedLinksController < ActionController::Base
  TRACKING_PARAM_KEYS = %w[gclid fbclid ttclid utm_source utm_medium utm_campaign utm_term utm_content].freeze

  def show
    tracked_link = Ctwa::TrackedLink.find_by(code: params[:code].to_s.upcase)
    return head :not_found if tracked_link.blank?

    # rubocop:disable Rails/SkipsModelValidations
    Ctwa::TrackedLink.increment_counter(:clicks_count, tracked_link.id)
    # rubocop:enable Rails/SkipsModelValidations
    redirect_to redirect_url_for(tracked_link), allow_other_host: true, status: :found
  end

  private

  def redirect_url_for(tracked_link)
    tracking_params = whitelisted_tracking_params
    return tracked_link.wa_link if tracking_params.blank?

    tracked_link_click = Ctwa::TrackedLinkClick.create!(
      account: tracked_link.account,
      tracked_link: tracked_link,
      params: tracking_params,
      user_agent: request.user_agent.to_s.truncate(255)
    )

    wa_link_for(tracked_link, tracked_link_click.token)
  rescue StandardError => e
    Rails.logger.warn("[Ctwa::TrackedLinks] failed to capture tracked link click: #{e.class.name}")
    tracked_link.wa_link
  end

  def whitelisted_tracking_params
    request.query_parameters.slice(*TRACKING_PARAM_KEYS)
  end

  def wa_link_for(tracked_link, token)
    phone = tracked_link.inbox&.channel.try(:phone_number).to_s.delete('+')
    return tracked_link.wa_link if phone.blank?

    text = CGI.escape("#{tracked_link.prefilled_text} ##{token}")

    "https://wa.me/#{phone}?text=#{text}"
  end
end
# rubocop:enable Rails/ApplicationController
