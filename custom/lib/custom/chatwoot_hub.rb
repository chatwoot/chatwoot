# frozen_string_literal: true

# Custom overlay — este arquivo NUNCA é sobrescrito por updates do Chatwoot upstream.
#
# Intercepta as chamadas para o Hub Oficial (hub.2.chatwoot.com) para garantir
# que nenhuma telemetria, registro ou envio de dados seja feito a partir desta
# instância customizada (100% de privacidade).
#
# O arquivo original `lib/chatwoot_hub.rb` possui:
# ChatwootHub.singleton_class.prepend_mod_with('ChatwootHub')
# Isso carrega este módulo e substitui os métodos Singleton do ChatwootHub.

module Custom::ChatwootHub
  extend ActiveSupport::Concern

  # Anula a sincronização diária (CheckNewVersionsJob).
  # Retorna um JSON/Hash vazio para não quebrar a lógica de extração da versão.
  def sync_with_hub
    Rails.logger.info '[CUSTOM] Sincronização com o Chatwoot Hub bloqueada (Telemetria Desativada).'
    {}
  end

  # Anula o registro de instância que ocorre na tela de Onboarding.
  def register_instance(company_name, owner_name, owner_email)
    Rails.logger.info '[CUSTOM] Registro de Instância no Chatwoot Hub bloqueado (Telemetria Desativada).'
    nil
  end

  # Anula qualquer envio de eventos estatísticos.
  def emit_event(event_name, event_data)
    Rails.logger.info "[CUSTOM] Evento ignorado: #{event_name} (Telemetria Desativada)."
    nil
  end

  # Anula o uso do Hub como relay para Notificações Push Mobile.
  # Para notificações mobile, as próprias credenciais do Firebase devem ser configuradas.
  def send_push(fcm_options)
    Rails.logger.warn '[CUSTOM] Envio de notificação Push via Relay Hub bloqueado. Configure seu próprio Firebase.'
    nil
  end
end
