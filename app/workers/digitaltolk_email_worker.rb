class DigitaltolkEmailWorker
  include Sidekiq::Worker
  sidekiq_options queue: :mailers, retry: 3

  def perform(params)
    data = JSON.parse(params).with_indifferent_access

    Digitaltolk::DigitaltolkMailer.send_email(data).deliver_later
  end
end
