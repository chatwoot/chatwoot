module Enterprise::Concerns::Inbox
  extend ActiveSupport::Concern

  included do
    has_one :captain_inbox, dependent: :destroy, class_name: 'CaptainInbox'
    has_one :captain_assistant,
            through: :captain_inbox,
            class_name: 'Captain::Assistant'
    has_many :inbox_capacity_limits, dependent: :destroy
    has_many :calls, dependent: :destroy_async
    has_many :conversation_outcomes, dependent: :destroy_async
    # Captain-generated audio of the channel's out_of_hours_call_message, played to Twilio callers
    has_one_attached :out_of_hours_call_audio

    before_create :ensure_create_permitted
  end

  # Incoming calls skip the ring and get the out-of-hours announcement instead
  def closed_for_calls?
    channel.try(:business_hours_calls_enabled?) && out_of_office?
  end

  def out_of_hours_call_audio_url
    url_for(out_of_hours_call_audio) if out_of_hours_call_audio.attached?
  end

  def ensure_create_permitted
    raise CustomExceptions::Inbox::LimitExceeded.new({}) if account.inboxes.count >= account.usage_limits[:inboxes]
  end
end
