# The super admin health page lists the WhatsApp connector next to Postgres and Redis: the
# instances registered and their versions, and, when none is, why the last start failed.
# Without it, the only place that said why "WhatsApp (native)" was missing from the inbox
# picker was the worker's log.
#
# Prepended rather than edited in, because the controller is upstream's and every line there
# is a conflict on every sync (#937 gave it back to upstream). The page renders every metric
# it is handed, so adding entries to @metrics is all it takes. Declared here instead of as an
# autoloaded module, for the reason import_guards.rb gives.
module WhatsappConnectorHealth
  def show
    super
    return unless Whatsapp::Connector.enabled?

    whatsapp_connector_metrics(Whatsapp::Connector::Status.new)
  rescue Whatsapp::Session::Errors::ProviderUnavailable => e
    @metrics[t('super_admin.instance_status.whatsapp_connector.label')] = t('super_admin.instance_status.whatsapp_connector.unreachable',
                                                                            error: e.message)
  end

  private

  def whatsapp_connector_metrics(status)
    scope = 'super_admin.instance_status.whatsapp_connector'
    @metrics[t("#{scope}.label")] = t(status.running? ? "#{scope}.running" : "#{scope}.not_running")
    status.instances.each do |instance|
      @metrics[t("#{scope}.instance", id: instance.id)] = instance.version
    end
    status.start_failures.each do |failure|
      @metrics[t("#{scope}.start_error", instance: failure.instance)] = "#{failure.at}: #{failure.error}"
    end
  end
end

Rails.application.config.to_prepare do
  SuperAdmin::InstanceStatusesController.prepend(WhatsappConnectorHealth)
end
