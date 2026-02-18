# frozen_string_literal: true

module Crm
  # Job para mantener los tokens de CRM actualizados
  # Se ejecuta periódicamente (cada 30 minutos) para refrescar tokens
  # que están próximos a expirar, evitando fallas en tiempo real
  class TokenMaintenanceJob < ApplicationJob
    queue_as :low

    def perform
      refresh_count = 0
      error_count = 0

      Integrations::Hook.crm_hooks.enabled.find_each do |hook|
        next unless hook.token_expired?

        hook.refresh_access_token!
        refresh_count += 1
        Rails.logger.info "✓ Token refreshed for #{hook.app_id} hook ##{hook.id}"
      rescue StandardError => e
        error_count += 1
        Rails.logger.error "✗ Token refresh failed for #{hook.app_id} hook ##{hook.id}: #{e.message}"

        # Notificar a administradores si hay múltiples fallos
        notify_admins_if_critical(hook, e) if error_count > 3
      end

      Rails.logger.info "Token maintenance completed: #{refresh_count} refreshed, #{error_count} errors"
    end

    private

    def notify_admins_if_critical(hook, error)
      # TODO: Implementar notificación a administradores
      # Puede ser por email, Slack, etc.
      Rails.logger.error "CRITICAL: Multiple token refresh failures detected"
    end
  end
end
