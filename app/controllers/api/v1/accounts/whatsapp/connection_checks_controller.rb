# CUSTOMIZAÇÃO_SYNAPSEOS
# Endpoint da página "Conexão WhatsApp" (Configurações, admin-only).
#   GET    /api/v1/accounts/:account_id/whatsapp/connection_check  -> último check persistido
#   POST   /api/v1/accounts/:account_id/whatsapp/connection_check  -> roda o check AGORA
class Api::V1::Accounts::Whatsapp::ConnectionChecksController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization

  def show
    render json: { data: avisa_channels.map { |c| serialize(c, c.provider_config['last_connection_check']) } }
  end

  def create
    data = avisa_channels.map do |channel|
      result = Whatsapp::AvisaConnectionCheckService.new(channel: channel).perform
      Whatsapp::AvisaConnectionCheckService.broadcast_disconnected(channel, result) if result.status == 'disconnected'
      serialize(channel, 'status' => result.status, 'http' => result.http, 'checked_at' => result.checked_at.iso8601)
    end
    render json: { data: data }
  end

  private

  def check_admin_authorization
    render_unauthorized('Acesso restrito a administradores') unless Current.account_user&.administrator?
  end

  def avisa_channels
    Channel::Whatsapp.where(account: Current.account, provider: 'avisa')
  end

  def serialize(channel, check)
    {
      inbox_id: channel.inbox&.id,
      inbox_name: channel.inbox&.name,
      phone_number: channel.phone_number,
      status: check&.dig('status') || 'unknown',
      http: check&.dig('http'),
      checked_at: check&.dig('checked_at')
    }
  end
end
