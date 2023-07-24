module Enterprise::WidgetsController
  private

  def ensure_location_is_supported
    countries = @web_widget.inbox.account.custom_attributes['allowed_countries']
    return if countries.blank?

    geocoder_result = IpLookupService.new.perform(request.remote_ip)
    return unless geocoder_result

    country_enabled = countries.include?(geocoder_result.country_code)
    render json: { error: 'Location is not supported' }, status: :unauthorized unless country_enabled
  end
end
