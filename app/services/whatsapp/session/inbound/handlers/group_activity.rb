# A hint that these groups have been active. It carries no detail, so it only refreshes
# the chat list order and asks for a soft sync, which is throttled by the sync job.
class Whatsapp::Session::Inbound::Handlers::GroupActivity < Whatsapp::Session::Inbound::Handlers::Base
  def perform
    return :ignored unless capability?(:groups)

    groups = Array(payload.groups).reject { |group| ignorable_chat?(group) }
    return :ignored if groups.empty?

    groups.each { |group| refresh(group) }
    :handled
  end

  private

  def refresh(group)
    inbound::Locks.with_chat_lock(inbox, group.id) do
      resolver = inbound::GroupResolver.new(inbox: inbox, group: group)
      result = resolver.perform
      conversation = resolver.conversation_for(result.group_contact_inbox)

      # Only where the sync can actually run. The job's own 15 minute cooldown reads
      # `group_last_synced_at`, which the syncer writes and a refused sync never reaches,
      # so on a receive-only inbox the cooldown would never engage and every reported
      # activity would enqueue another job that does nothing.
      Contacts::SyncGroupJob.perform_later(result.group_contact, soft: true, channel: channel) if capability?(:group_management)
      conversation.update_columns(last_activity_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      conversation.dispatch_conversation_updated_event
    end
  end
end
