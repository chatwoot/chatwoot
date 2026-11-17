# Emails the admins of every embedded signup inbox on a WABA whose coexistence number is still offboarded,
# while finishing the WhatsApp Business app's registration can still restore it. See Whatsapp::CoexistenceOffboarding.
class Channels::Whatsapp::OffboardedReminderJob < ApplicationJob
  queue_as :default

  def perform(waba_id, offboarded_at)
    return unless Whatsapp::CoexistenceOffboarding.still_offboarded?(waba_id, offboarded_at)

    Channel::Whatsapp.embedded_signup_on_waba(waba_id).includes(:account, :inbox).find_each do |channel|
      # Meta has already removed our access, so the reconnect banner and email have taken over.
      next if channel.reauthorization_required? || channel.inbox.blank?

      AdministratorNotifications::ChannelNotificationsMailer.with(account: channel.account).whatsapp_offboarded(channel.inbox).deliver_later
    end
  end
end
