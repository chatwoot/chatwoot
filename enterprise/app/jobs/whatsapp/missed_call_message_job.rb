class Whatsapp::MissedCallMessageJob < ApplicationJob
  queue_as :default

  def perform(call_id)
    call = Call.find_by(id: call_id)
    Whatsapp::MissedCallMessageService.new(call: call).perform if call
  end
end
