# Fans the connection check out over the inboxes that need one, every five minutes.
#
# Only the providers that have to be polled, and only the sessions that are up or on their
# way up: a closed one has nothing to report, and its way back is a connect the operator
# asks for or a webhook the provider sends. `connecting` stays in because this poll is what
# writes it when it lands mid-reconnect, and a provider that reconnects on its own sends
# nothing afterwards, so leaving it out would pin the inbox there for good.
class Whatsapp::Session::ConnectionCheckSchedulerJob < ApplicationJob
  queue_as :low

  def perform
    providers = polled_providers
    return if providers.empty?

    Channel::Whatsapp.where(provider: providers)
                     .where("provider_connection->>'connection' IN (?)", %w[open connecting])
                     .find_each { |channel| Whatsapp::Session::ConnectionCheckJob.perform_later(channel) }
  end

  private

  # Asked of the backends rather than listed here, so a provider that stops needing a poll
  # (or a new one that does) is a single answer in one class instead of a literal to keep
  # in step.
  def polled_providers
    Whatsapp::Session::PROVIDERS.select do |provider|
      Whatsapp::Session::Registry.descriptor(provider)&.backend_class&.state_polling?
    end
  end
end
