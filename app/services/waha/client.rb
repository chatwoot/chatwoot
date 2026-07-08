require 'uri'

module Waha
  # Cliente HTTP fino do motor externo (WAHA). Autentica via X-Api-Key. Levanta
  # Waha::Client::Error em qualquer falha, com status + corpo para diagnóstico.
  class Client
    class Error < StandardError; end

    DEFAULT_TIMEOUT = 20

    def initialize(config: Waha::Config)
      @base = config.api_url
      @key = config.api_key
    end

    # ---- SESSÕES ----
    def create_session(name, start: true, config: {})
      post('/api/sessions', { name: name, start: start, config: config })
    end

    def get_session(name)
      get("/api/sessions/#{name}")
    end

    def list_sessions(all: true)
      get("/api/sessions?all=#{all}")
    end

    def start_session(name)
      post("/api/sessions/#{name}/start")
    end

    def restart_session(name)
      post("/api/sessions/#{name}/restart")
    end

    def logout_session(name)
      post("/api/sessions/#{name}/logout")
    end

    def delete_session(name)
      delete("/api/sessions/#{name}")
    end

    # QR como valor cru (string) — { "value": "..." }. O proxy de imagem fica no controller.
    def qr_value(name)
      get("/api/#{name}/auth/qr?format=raw")
    end

    # QR como bytes PNG (para o controller repassar como imagem).
    def qr_image(name)
      raw_get("/api/#{name}/auth/qr")
    end

    # ---- APPS (conector de mensagens) ----
    def create_app(session:, app_id:, config:, app: 'chatwoot')
      post('/api/apps', { id: app_id, session: session, app: app, enabled: true, config: config })
    end

    def list_apps(session)
      get("/api/apps?session=#{session}")
    end

    def delete_app(app_id)
      delete("/api/apps/#{app_id}")
    end

    def check_contact_exists(phone:, session:)
      query = URI.encode_www_form(phone: phone, session: session)
      get("/api/contacts/check-exists?#{query}")
    end

    private

    def headers
      { 'X-Api-Key' => @key, 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
    end

    def post(path, body = nil)
      request(:post, path, body)
    end

    def get(path)
      request(:get, path)
    end

    def delete(path)
      request(:delete, path)
    end

    def request(method, path, body = nil)
      response = HTTParty.public_send(
        method, "#{@base}#{path}",
        headers: headers, body: body.nil? ? nil : body.to_json, timeout: DEFAULT_TIMEOUT
      )
      raise Error, "WAHA #{method.upcase} #{path} -> #{response.code}: #{response.body.to_s[0, 300]}" unless response.success?

      response.parsed_response
    rescue HTTParty::Error, SocketError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
      raise Error, "WAHA #{method.upcase} #{path} falhou: #{e.message}"
    end

    # GET cru (bytes) para imagens.
    def raw_get(path)
      response = HTTParty.get("#{@base}#{path}", headers: { 'X-Api-Key' => @key }, timeout: DEFAULT_TIMEOUT)
      raise Error, "WAHA GET #{path} -> #{response.code}" unless response.success?

      { body: response.body, content_type: response.headers['content-type'] }
    rescue HTTParty::Error, SocketError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
      raise Error, "WAHA GET #{path} falhou: #{e.message}"
    end
  end
end
