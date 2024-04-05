module ChatbotHelper
  # website_token --> chatbot_id
  WEBSITE_TOKEN_TO_CHATBOT_ID_MAPPING = {}

  INBOX_ID_TO_WEBSITE_TOKEN_MAPPING = {}

  CONVERSATION_ID_TO_BOT_STATUS_MAPPING = {}

  CHATBOT_ID_TO_INBOX_NAME_MAPPING = {}

  def self.toggle_bot_status(conversation_id)
    CONVERSATION_ID_TO_BOT_STATUS_MAPPING[conversation_id] = !CONVERSATION_ID_TO_BOT_STATUS_MAPPING[conversation_id]
  end

  # Method to get website_token corresponding to an inbox_id
  def self.get_website_token_from_inbox_id(inbox_id)
    INBOX_ID_TO_WEBSITE_TOKEN_MAPPING[inbox_id]
  end

  # Method to get chatbot_id corresponding to a website_token
  def self.get_chatbot_id(website_token)
    WEBSITE_TOKEN_TO_CHATBOT_ID_MAPPING[website_token]
  end
end
