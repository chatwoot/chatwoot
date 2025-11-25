module Voice::Conference::Name
  def self.for(conversation)
    "conf_account_#{conversation.account_id}_conv_#{conversation.display_id}"
  end
end
