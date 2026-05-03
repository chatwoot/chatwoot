class Whatsapp::JusmonitoriaTemplateStatusForwardJob < ApplicationJob
  queue_as :low

  def perform(payload)
    Whatsapp::JusmonitoriaTemplateStatusForwarder.new(payload).call
  end
end
