class DeadLetterMailbox < ApplicationMailbox
  def process
    Rails.logger.warn "Undeliverable email from #{mail.from} to #{mail.to}"
  end
end