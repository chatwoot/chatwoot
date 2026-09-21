class Copilot::V2::ChatService < Llm::BaseAiService
  attr_reader :account, :user, :thread, :assistant

  def initialize(account:, user:, thread:, assistant: nil)
    super(feature: 'copilot', account: account)
    @account = account
    @user = user
    @thread = thread
    @assistant = assistant
  end

  def generate_response
    history = thread.previous_history
    llm_chat = chat.with_instructions(<<~PROMPT)
      You are Copilot, a support assistant for the current user.
      Answer using only the information provided in this chat. Account data retrieval is not available.
      Do not invent account records or claim to have searched or changed them.
      Respond in #{account.locale_english_name} unless the user requests another language.
    PROMPT
    history[0...-1].each { |message| llm_chat.add_message(role: message[:role].to_sym, content: message[:content]) }
    response = llm_chat.ask(history.last.fetch(:content))
    thread.copilot_messages.create!(message_type: :assistant, message: { content: response.content })
    account.increment_response_usage
    response
  end
end
