# Off the request: a Baileys lookup may take up to its 90 s ceiling against a wedged socket,
# and every agent opening a flagged conversation would hold a web thread for that long.
class Whatsapp::NumberRecheckJob < ApplicationJob
  queue_as :low

  def perform(conversation)
    Whatsapp::NumberRecheckService.new(conversation: conversation).perform
  end
end
