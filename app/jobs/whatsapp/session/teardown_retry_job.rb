# Sends again a teardown the connector never attempted. Scheduled by
# Whatsapp::Session::TeardownRetry, which also decides the wait; this only checks, at send
# time, that the teardown is still wanted.
class Whatsapp::Session::TeardownRetryJob < ApplicationJob
  queue_as :high

  # A Redis that is down, or a connector fleet speaking another protocol: the frame was not
  # written, so a later attempt can still deliver it.
  retry_on Whatsapp::Session::Errors::ProviderUnavailable, wait: :polynomially_longer, attempts: 5

  def perform(session_id, command_type)
    return unless Whatsapp::Session::TeardownRetry.wanted?(session_id)

    Whatsapp::Session::TeardownRetry.send_again(session_id, command_type)
  end
end
