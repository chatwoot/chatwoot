class Conversations::CreateWithInitialMessage
  def initialize(user:, contact_inbox:, params:)
    @user = user
    @contact_inbox = contact_inbox
    @params = params
  end

  # Returns [conversation, nil] on success, or [conversation_or_nil, error_message] when the initial message fails.
  def perform
    initial_message_error = nil
    conversation = nil
    ActiveRecord::Base.transaction do
      conversation = ConversationBuilder.new(params: @params, contact_inbox: @contact_inbox).perform
      if @params[:message].present?
        begin
          Messages::MessageBuilder.new(@user, conversation, @params[:message]).perform
        rescue StandardError => e
          initial_message_error = e.message
          raise ActiveRecord::Rollback
        end
      end
    end
    [conversation, initial_message_error]
  end
end
