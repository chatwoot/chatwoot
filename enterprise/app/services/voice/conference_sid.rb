module Voice
  module ConferenceSid
    def self.friendly_name(conversation)
      "conf_account_#{conversation.account_id}_conv_#{conversation.display_id}"
    end
  end
end
