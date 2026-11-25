# The WhatsApp connector's event consumer runs inside Sidekiq by default: it is the
# process that is already there, already restarted on deploy, and already quiesced
# before shutdown. `WHATSAPP_CONNECTOR_CONSUMER=standalone` moves it to its own process
# (`rails whatsapp:consumer`), and `off` disables it.
#
# The flags are read straight from the environment here: application constants are not
# autoloadable yet while initializers run. The supervisor itself is built inside the
# startup hook, which fires long after boot.
if ENV.fetch('WHATSAPP_CONNECTOR_ENABLED', 'true') != 'false' &&
   ENV.fetch('WHATSAPP_CONNECTOR_CONSUMER', 'sidekiq') == 'sidekiq'
  Sidekiq.configure_server do |config|
    supervisor = nil

    config.on(:startup) do
      supervisor = Whatsapp::Connector::Consumer::Supervisor.new
      supervisor.start
    end
    # Quiet comes before shutdown on a rolling deploy: releasing the shards here lets
    # the incoming process pick them up while this one finishes its jobs.
    config.on(:quiet) { supervisor&.quiet }
    config.on(:shutdown) { supervisor&.stop }
  end
end
