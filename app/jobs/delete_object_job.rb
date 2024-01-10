class DeleteObjectJob < ApplicationJob
  queue_as :low

  def perform(object, user = nil, ip = nil)
    object.destroy!
    process_post_deletion_tasks(object, user, ip)
  end

  def process_post_deletion_tasks(object, user, ip); end
end

DeleteObjectJob.prepend_mod_with('DeleteObjectJob')
