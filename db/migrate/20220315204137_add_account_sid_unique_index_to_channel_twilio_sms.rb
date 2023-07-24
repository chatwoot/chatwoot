class AddAccountSidUniqueIndexToChannelTwilioSms < ActiveRecord::Migration[6.1]
  def change
    clear_possible_duplicates

    has_duplicates = Channel::TwilioSms.select(:phone_number).group(:phone_number).having('count(*) > 1').exists?

    if has_duplicates
      raise <<~ERR.squish
        ERROR: You have duplicate values for phone_number in "channel_twilio_sms".
        This causes Twilio account lookup to behave unpredictably. Please eliminate the duplicates
        and then re-run this migration.
      ERR
    end

    remove_index :channel_twilio_sms, [:account_id, :phone_number], unique: true
    add_index :channel_twilio_sms, :phone_number, unique: true
    # since look ups are done via account_sid + phone_number, we need to add a unique index
    add_index :channel_twilio_sms, [:account_sid, :phone_number], unique: true
  end

  def clear_possible_duplicates
    # based on the look up in saas it seems like only the first inbox is used in case of duplicates,
    # so lets try to clear our inboxes with out conversations
    duplicate_phone_numbers = Channel::TwilioSms.select(:phone_number).group(:phone_number).having('count(*) > 1').collect(&:phone_number)
    duplicate_phone_numbers.each do |phone_number|
      # we are skipping the first inbox that was created
      Channel::TwilioSms.where(phone_number: phone_number).drop(1).each do |channel|
        inbox = channel.inbox
        # skip inboxes with conversations
        next if inbox.conversations.count.positive?

        inbox.destroy
      end
    end

    # clear the accounts created with twilio sandbox whatsapp number
    # Channel::TwilioSms.where(phone_number: 'whatsapp:+14155238886').each { |channel| channel.inbox.destroy }
  end
end
