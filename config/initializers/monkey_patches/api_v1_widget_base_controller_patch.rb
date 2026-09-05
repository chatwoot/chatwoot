Rails.application.config.to_prepare do
  Api::V1::Widget::BaseController.class_eval do
    private

    def create_conversation
      conversation = ::Conversation.create!(conversation_params)
      create_like_dislike_csat_hint_message(conversation)
      conversation
    end

    def create_like_dislike_csat_hint_message(conversation)
      return unless inbox.csat_survey_enabled?
      return unless inbox.csat_config&.dig('display_type') == 'like_dislike'
      return if inbox.csat_config['like_dislike_hint_enabled'] == false
    
      hint = inbox.csat_config['like_dislike_hint_message'].presence ||
             I18n.t('conversations.templates.csat_like_dislike_hint')
    
      conversation.messages.create!(
        account_id:   conversation.account_id,
        inbox_id:     conversation.inbox_id,
        message_type: :template,
        content:      hint
      )
    end
  end
end
