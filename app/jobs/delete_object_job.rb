class DeleteObjectJob < ApplicationJob
  queue_as :low

  def perform(object, user = nil, ip = nil)
    object.destroy!
    process_post_deletion_tasks(object, user, ip)
  end

  def process_post_deletion_tasks(object, _user, _ip)
    return unless object.channel.is_a?(Channel::WhatsappUnofficial)

    waha_service = Waha::WahaService.instance
    waha_service.delete_device(device_id: object.channel.id)
  end
end

DeleteObjectJob.prepend_mod_with('DeleteObjectJob')
