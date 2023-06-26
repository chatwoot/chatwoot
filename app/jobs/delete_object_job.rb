class DeleteObjectJob < ApplicationJob
  queue_as :low

  def perform(object, user = nil, ip = nil)
    audited_changes = object.attributes.except('id', 'created_at', 'updated_at')
    object.destroy!
    create_audit_entry(object, user, ip, audited_changes)
  end

  def create_audit_entry(object, user, ip, audited_changes); end
end

DeleteObjectJob.prepend_mod_with('DeleteObjectJob')
