module ReadReplicaWriterStickiness
  extend ActiveSupport::Concern

  included do
    after_action :mark_read_replica_writer_stickiness
  end

  private

  def mark_read_replica_writer_stickiness
    return unless response.successful?
    return unless mutation_request_for_read_replica?

    ReadReplica::WriterStickiness.mark!(read_replica_actor_key)
  end

  def mutation_request_for_read_replica?
    return false if read_replica_routed_action?
    return true unless request.get? || request.head?

    controller_path == 'api/v1/widget/conversations' && action_name == 'toggle_status'
  end
end
