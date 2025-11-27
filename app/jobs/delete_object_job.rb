class DeleteObjectJob < ApplicationJob
  queue_as :low

  BATCH_SIZE = 5_000
  HEAVY_ASSOCIATIONS = {
    Account => %i[conversations contacts inboxes reporting_events],
    Inbox => %i[conversations contact_inboxes reporting_events]
  }.freeze

  def perform(object, user = nil, ip = nil)
    # Pre-purge heavy associations for large objects to avoid
    # timeouts & race conditions due to destroy_async fan-out.
    purge_heavy_associations(object)
    object.destroy!
    process_post_deletion_tasks(object, user, ip)
  end

  def process_post_deletion_tasks(object, user, ip); end

  private

  def purge_heavy_associations(object)
    klass = HEAVY_ASSOCIATIONS.keys.find { |k| object.is_a?(k) }
    return unless klass

    HEAVY_ASSOCIATIONS[klass].each do |assoc|
      next unless object.respond_to?(assoc)

      batch_destroy(object.public_send(assoc))
    end
  end

  def batch_destroy(relation)
    relation.find_in_batches(batch_size: BATCH_SIZE) do |batch|
      batch.each(&:destroy!)
    end
  end
end

DeleteObjectJob.prepend_mod_with('DeleteObjectJob')
