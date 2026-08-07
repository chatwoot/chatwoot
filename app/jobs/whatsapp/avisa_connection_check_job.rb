# CUSTOMIZAÇÃO_SYNAPSEOS
# Roda 3x/dia (09:00 / 14:00 / 17:00 BRT — cron 0 12,17,20 UTC no schedule.yml).
# Checa cada canal WhatsApp com provider Avisa; se a instância caiu, avisa os
# admins da conta (toast via ActionCableBroadcastJob). O resultado fica persistido
# em provider_config['last_connection_check'] pra página de Configurações ler.
class Whatsapp::AvisaConnectionCheckJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    avisa_channels.find_each { |channel| check(channel) }
  end

  private

  def avisa_channels
    Channel::Whatsapp.where(provider: 'avisa')
  end

  def check(channel)
    result = Whatsapp::AvisaConnectionCheckService.new(channel: channel).perform
    Rails.logger.info("[AVISA] connection check canal=#{channel.id} status=#{result.status} http=#{result.http}")
    Whatsapp::AvisaConnectionCheckService.broadcast_disconnected(channel, result) if result.status == 'disconnected'
  rescue StandardError => e
    Rails.logger.error("[AVISA] connection check falhou p/ canal #{channel.id}: #{e.message}")
  end
end
