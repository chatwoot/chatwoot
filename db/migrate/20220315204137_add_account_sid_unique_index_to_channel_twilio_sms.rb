class AddAccountSidUniqueIndexToChannelTwilioSms < ActiveRecord::Migration[6.1]
  def change
    has_duplicates = Channel::TwilioSms
                     .select(1)
                     .where.not(account_sid: nil)
                     .where.not(phone_number: nil)
                     .group(:account_sid, :phone_number)
                     .having('count(*) > 1')
                     .exists?

    if has_duplicates
      raise <<~ERR.squish
        ERROR: You have duplicate values for account_sid + phone_number in "channel_twilio_sms".
        This causes Twilio account lookup to behave unpredictably. Please eliminate the duplicates
        and then re-run this migration.
      ERR
    end

    add_index :channel_twilio_sms, [:account_sid, :phone_number], unique: true
  end
end
