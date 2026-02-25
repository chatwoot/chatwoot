module Enterprise::Api::V1::Accounts::PortalsController
  def ssl_status
    return render_could_not_create_error(I18n.t('portals.ssl_status.custom_domain_not_configured')) if @portal.custom_domain.blank?

    result = Cloudflare::CheckCustomHostnameService.new(portal: @portal).perform

    return render_could_not_create_error(result[:errors]) if result[:errors].present?

    ssl_settings = @portal.ssl_settings || {}
    render json: {
      status: ssl_settings['cf_status'],
      verification_errors: ssl_settings['cf_verification_errors']
    }
  end
end
