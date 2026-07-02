module Waha
  # Orquestra, em poucas chamadas, tudo o que hoje é feito na mão: cria a caixa
  # (canal API igual ao padrão), cria a sessão no motor externo e liga o conector
  # de mensagens — deixando só o passo humano de ler o QR.
  class InboxProvisioner
    class Error < StandardError; end

    Result = Struct.new(:inbox, :session, :app_id, keyword_init: true)

    # Celular BR no formato 55 + DDD(2) + 9 dígitos (ex.: 5511987654321) = 13 dígitos.
    PHONE_RE = /\A55\d{11}\z/

    def initialize(account:, phone:, display_name: nil, ai_agent: false,
                   api_access_token: nil,
                   client: Waha::Client.new, config: Waha::Config)
      @account = account
      @phone = normalize_phone(phone)
      @display_name = display_name.to_s.strip
      @ai_agent = ActiveModel::Type::Boolean.new.cast(ai_agent)
      @api_access_token = api_access_token.to_s
      @client = client
      @config = config
    end

    def perform
      raise Error, 'integration_not_configured' unless @config.enabled?
      raise Error, 'invalid_phone' unless @phone.match?(PHONE_RE)
      raise Error, 'account_token_missing' if account_token.blank?

      app_id = "app_#{SecureRandom.hex(16)}"
      callback = @config.callback_url(@phone, app_id)

      inbox = nil
      ActiveRecord::Base.transaction do
        inbox = create_inbox(callback, app_id)
      end

      # Fora da transação do banco: chamadas externas ao motor. Se falhar, desfaz a caixa.
      begin
        @client.create_session(@phone, start: true, config: { ignore: @config.session_ignore })
        @client.create_app(session: @phone, app_id: app_id, config: app_config(inbox))
      rescue StandardError => e
        cleanup_inbox(inbox)
        cleanup_remote(app_id)
        # Detalhe (que pode conter resposta do motor) só nos logs; ao cliente vai um código estável.
        Rails.logger.error("[Waha] provisioning failed for #{@phone}: #{e.message}")
        raise Error, 'remote_setup_failed'
      end

      Result.new(inbox: inbox, session: @phone, app_id: app_id)
    end

    private

    def create_inbox(callback, app_id)
      channel = @account.api_channels.create!(
        webhook_url: callback,
        additional_attributes: {
          'provider' => 'waha',
          'session' => @phone,
          'app_id' => app_id,
          'kind' => @ai_agent ? 'ai' : 'human',
          # Já nasce marcada como caixa de campanha WhatsApp API — uma caixa WAHA É, por definição,
          # uma caixa de WhatsApp API; sem isto o seletor de campanha (filtra por campaign_channel_type)
          # nunca a enxerga e o disparo "one-click" fica inacessível.
          'campaign_channel_type' => Channel::Api::WHATSAPP_API_CAMPAIGN_CHANNEL_TYPE,
          'whatsapp_api_provider' => Channel::Api::WHATSAPP_API_CAMPAIGN_PROVIDER
        }
      )
      @account.inboxes.create!(name: inbox_display_name, channel: channel)
    end

    # IA: nome = telefone (automação depende). Humano: nome livre, telefone na sessão.
    def inbox_display_name
      return @phone if @ai_agent
      @display_name.presence || @phone
    end

    def app_config(inbox)
      {
        url: @config.chatwoot_base_url,
        accountId: @account.id,
        accountToken: account_token,
        inboxId: inbox.id,
        inboxIdentifier: inbox.channel.identifier,
        locale: 'pt-BR',
        linkPreview: 'OFF',
        templates: {},
        commands: { server: true, queue: true },
        conversations: { markAsRead: true, sort: @config.conversation_sort, status: nil }
      }
    end

    def normalize_phone(phone)
      phone.to_s.gsub(/\D/, '')
    end

    def cleanup_inbox(inbox)
      inbox&.destroy
    rescue StandardError
      nil
    end

    def cleanup_remote(app_id)
      @client.delete_app(app_id)
    rescue StandardError
      nil
    ensure
      begin
        @client.delete_session(@phone)
      rescue StandardError
        nil
      end
    end

    def account_token
      @api_access_token.presence || @config.account_token
    end
  end
end
