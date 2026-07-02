class Channels::Whatsapp::TemplatesSyncSchedulerJob < ApplicationJob
  queue_as :low

  def perform
    # Threshold reduzido de 3h (upstream) para 1 minuto: template aprovado na
    # Meta aparece no próximo tick do TriggerScheduledItemsJob (a cada 5 min)
    # em vez de esperar até 3h. Custo: 1 chamada Graph por canal oficial a cada
    # 5 min — desprezível na nossa escala e ainda protegido pelo limit abaixo.
    Channel::Whatsapp.order(Arel.sql('message_templates_last_updated IS NULL DESC, message_templates_last_updated ASC'))
                     .where('message_templates_last_updated <= ? OR message_templates_last_updated IS NULL', 1.minute.ago)
                     .limit(Limits::BULK_EXTERNAL_HTTP_CALLS_LIMIT)
                     .each do |channel|
      Channels::Whatsapp::TemplatesSyncJob.perform_later(channel)
    end
  end
end
