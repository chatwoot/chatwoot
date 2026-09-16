class Captain::Playground::ResponseJob < ApplicationJob
  queue_as :default

  EVENT_NAME = 'captain.playground.response'.freeze

  def perform(assistant:, user:, request_id:, request:)
    request = request.symbolize_keys
    response = response_payload(
      assistant: assistant,
      message_content: request[:message_content],
      message_history: request[:message_history],
      playground_config: request[:playground_config],
      playground_config_supplied: request[:playground_config_supplied]
    )

    ActionCableBroadcastJob.perform_later(
      [user.pubsub_token],
      EVENT_NAME,
      response.merge(account_id: assistant.account_id, request_id: request_id)
    )
  end

  private

  def response_payload(assistant:, message_content:, message_history:, playground_config:, playground_config_supplied:)
    generate_response(
      assistant: assistant,
      message_content: message_content,
      message_history: message_history,
      playground_config: playground_config,
      playground_config_supplied: playground_config_supplied
    )
  rescue Captain::Playground::Configuration::Invalid => e
    { error: e.message, errors: e.errors }
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: assistant.account).capture_exception
    { error: true }
  end

  def generate_response(assistant:, message_content:, message_history:, playground_config:, playground_config_supplied:)
    return generate_default_response(assistant, message_content, message_history) unless playground_config_supplied

    Captain::Playground::Runner.new(
      assistant: assistant,
      configuration_params: playground_config,
      message_history: playground_message_history(message_history, message_content)
    ).generate_response
  end

  def generate_default_response(assistant, message_content, message_history)
    run_options = Captain::Assistant::AgentRunnerService::RunOptions.new(source: 'playground')
    Captain::Assistant::AgentRunnerService.new(assistant: assistant, run_options: run_options).generate_response(
      message_history: playground_message_history(message_history, message_content)
    )
  end

  def playground_message_history(message_history, message_content)
    history = message_history.map { |message| message.to_h.symbolize_keys }
    return history if message_content.blank?

    current_user_message = { role: 'user', content: message_content }
    return history if history.last == current_user_message

    history + [current_user_message]
  end
end
