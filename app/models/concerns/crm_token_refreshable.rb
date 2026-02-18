# frozen_string_literal: true

module CrmTokenRefreshable
  extend ActiveSupport::Concern

  # Margen de 5 minutos antes de expiración para refrescar
  TOKEN_REFRESH_MARGIN = 5.minutes

  CRM_PROVIDERS = %w[zoho salesforce hubspot kommo].freeze

  included do
    # Hook para refrescar token antes de validar
    before_validation :refresh_token_if_needed, if: :crm_hook?
  end

  def crm_hook?
    CRM_PROVIDERS.include?(app_id)
  end

  def token_expired?
    # Sin token es equivalente a expirado: necesita obtenerlo
    return true unless credentials['access_token'].present?
    return false unless credentials['token_expires_at'].present?

    expires_at = Time.zone.parse(credentials['token_expires_at'])
    Time.current >= (expires_at - TOKEN_REFRESH_MARGIN)
  rescue ArgumentError
    # Si hay error parseando la fecha, considerar expirado
    true
  end

  def credentials
    # Support both flat structure and nested credentials structure
    if settings['credentials'].present?
      settings['credentials']
    else
      settings
    end
  end

  def credentials=(value)
    # Store in flat structure
    settings.merge!(value)
  end

  def refresh_token_if_needed
    return unless token_expired?

    refresh_access_token!
  rescue StandardError => e
    Rails.logger.error "Token refresh failed for #{app_id} hook ##{id}: #{e.message}"
    # No lanzar error, permitir que continúe y falle en el request si es necesario
  end

  def refresh_access_token!
    refresher = token_refresher_class.new(self)
    new_credentials = refresher.refresh!

    update_credentials!(new_credentials)

    Rails.logger.info "Token refreshed successfully for #{app_id} hook ##{id}"
  end

  private

  def token_refresher_class
    "Crm::#{app_id.classify}::TokenRefresher".constantize
  rescue NameError => e
    raise "TokenRefresher not found for #{app_id}: #{e.message}"
  end

  def update_credentials!(new_credentials)
    # Merge nuevas credenciales directamente en settings
    settings.merge!(new_credentials)

    # Calcular token_expires_at si viene expires_in
    if new_credentials['expires_in'].present?
      expires_at = Time.current + new_credentials['expires_in'].to_i.seconds
      settings['token_expires_at'] = expires_at.iso8601
    end

    # Para Salesforce que usa issued_at en milisegundos
    if new_credentials['issued_at'].present? && new_credentials['expires_in'].blank?
      # Salesforce tokens duran 2 horas por defecto
      expires_at = Time.current + 2.hours
      settings['token_expires_at'] = expires_at.iso8601
    end

    save(validate: false)
  end
end
