module Whatsapp::BaileysHandlers::GroupsActivity
  include Whatsapp::BaileysHandlers::Concerns::GroupEventHelper
  include GroupConversationHandler

  private

  def process_groups_activity
    activities = processed_params[:data]
    return if activities.blank?

    activities.each do |activity|
      jid = activity[:jid]
      next if jid.blank?

      with_contact_lock(jid) do
        group_contact_inbox = find_or_create_group_contact_inbox_by_jid(jid)
        conversation = find_or_create_group_conversation(group_contact_inbox)

        Contacts::SyncGroupJob.perform_later(group_contact_inbox.contact, soft: true)

        conversation.update_columns(last_activity_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
        conversation.dispatch_conversation_updated_event
      end
    end
  end
end
