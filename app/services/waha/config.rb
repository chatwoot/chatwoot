module Waha
  # Central de configuração da integração WhatsApp API (motor externo via WAHA).
  # TUDO vem de ENV para trocar de VPS mexendo só no ambiente. Nenhum segredo no git.
  class Config
    class << self
      def api_url
        ENV.fetch('WAHA_API_URL', '').to_s.chomp('/')
      end

      # URL pública usada para montar o callback que a caixa chama (pode diferir da api_url
      # atrás de proxy). Cai para api_url quando não setada.
      def public_url
        ENV.fetch('WAHA_PUBLIC_URL', api_url).to_s.chomp('/')
      end

      def api_key
        ENV.fetch('WAHA_API_KEY', '').to_s
      end

      # Base do nosso próprio app (usada na config do conector de mensagens).
      def chatwoot_base_url
        ENV.fetch('CHATWOOT_BASE_URL', ENV.fetch('FRONTEND_URL', '')).to_s.chomp('/')
      end

      # Caminho do callback do conector. O motor WAHA serve o receptor do plugin chatwoot no
      # PLURAL (/webhooks/chatwoot/{sessão}/{app_id}); o singular retorna 401 e o outbound nunca
      # chega ao WhatsApp. Mantido configurável por ENV para acompanhar a versão do motor.
      def webhook_path
        ENV.fetch('WAHA_CHATWOOT_WEBHOOK_PATH', '/webhooks/chatwoot').to_s
      end

      def conversation_sort
        ENV.fetch('WAHA_CONVERSATION_SORT', 'created_newest').to_s
      end

      # Filtros de evento por sessão. Por padrão ignoramos Status (os "stories" do WhatsApp),
      # listas de transmissão, canais e grupos — ruído para um atendimento 1:1.
      # Cada um é sobreponível por ENV para o whitelabel ajustar sem mexer no código.
      def session_ignore
        {
          status: bool_env('WAHA_IGNORE_STATUS', true),
          broadcast: bool_env('WAHA_IGNORE_BROADCAST', true),
          channels: bool_env('WAHA_IGNORE_CHANNELS', true),
          groups: bool_env('WAHA_IGNORE_GROUPS', true)
        }
      end

      def enabled?
        api_url.present? && api_key.present?
      end

      # URL final que vai no webhook da caixa: {public_url}{webhook_path}/{sessão}/{app_id}
      def callback_url(session, app_id)
        "#{public_url}#{webhook_path}/#{session}/#{app_id}"
      end

      private

      def bool_env(key, default)
        raw = ENV.fetch(key, nil)
        return default if raw.nil? || raw.to_s.strip.empty?

        ActiveModel::Type::Boolean.new.cast(raw)
      end
    end
  end
end
