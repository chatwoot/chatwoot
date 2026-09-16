require 'rails_helper'

RSpec.describe Captain::Playground::ResponseJob, type: :job do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:request_id) { 'playground-request-1' }
  let(:message_content) { 'Hello assistant' }
  let(:message_history) { [{ role: 'user', content: 'Previous message' }] }

  def perform_job(**overrides)
    described_class.perform_now(
      assistant: assistant,
      user: user,
      request_id: request_id,
      request: {
        message_content: message_content,
        message_history: message_history,
        **overrides
      }
    )
  end

  it 'generates a conversationless response with the agent runner' do
    agent_runner = instance_double(Captain::Assistant::AgentRunnerService)
    run_options = Captain::Assistant::AgentRunnerService::RunOptions.new(source: 'playground')
    allow(Captain::Assistant::AgentRunnerService).to receive(:new)
      .with(assistant: assistant, run_options: run_options)
      .and_return(agent_runner)
    allow(agent_runner).to receive(:generate_response).and_return(response: 'Assistant response')
    allow(ActionCableBroadcastJob).to receive(:perform_later)

    perform_job

    expect(agent_runner).to have_received(:generate_response).with(
      message_history: message_history + [{ role: 'user', content: message_content }]
    )
    expect(ActionCableBroadcastJob).to have_received(:perform_later).with(
      [user.pubsub_token],
      described_class::EVENT_NAME,
      { response: 'Assistant response', account_id: account.id, request_id: request_id }
    )
  end

  it 'does not duplicate the current message when it is already in history' do
    agent_runner = instance_double(Captain::Assistant::AgentRunnerService)
    allow(Captain::Assistant::AgentRunnerService).to receive(:new).and_return(agent_runner)
    allow(agent_runner).to receive(:generate_response).and_return(response: 'Assistant response')
    allow(ActionCableBroadcastJob).to receive(:perform_later)
    current_message = { role: 'user', content: message_content }

    perform_job(message_history: [current_message])

    expect(agent_runner).to have_received(:generate_response).with(message_history: [current_message])
  end

  it 'uses the ephemeral playground runner when configuration is supplied' do
    playground_runner = instance_double(Captain::Playground::Runner)
    playground_config = { 'scenario_ids' => [], 'knowledge_text' => 'Refunds take five days.' }
    allow(Captain::Playground::Runner).to receive(:new).with(
      assistant: assistant,
      configuration_params: playground_config,
      message_history: message_history + [{ role: 'user', content: message_content }]
    ).and_return(playground_runner)
    allow(playground_runner).to receive(:generate_response).and_return(
      response: 'Assistant response',
      run_details: { duration_ms: 12, events: [] }
    )

    expect(ActionCableBroadcastJob).to receive(:perform_later).with(
      [user.pubsub_token],
      described_class::EVENT_NAME,
      hash_including(
        response: 'Assistant response',
        run_details: { duration_ms: 12, events: [] },
        account_id: account.id,
        request_id: request_id
      )
    )

    perform_job(playground_config: playground_config, playground_config_supplied: true)
  end

  it 'broadcasts configuration errors for the playground to display' do
    invalid = Captain::Playground::Configuration::Invalid.new('knowledge_text' => ['is too long'])
    allow(Captain::Playground::Runner).to receive(:new).and_raise(invalid)

    expect(ActionCableBroadcastJob).to receive(:perform_later).with(
      [user.pubsub_token],
      described_class::EVENT_NAME,
      hash_including(
        error: invalid.message,
        errors: invalid.errors,
        account_id: account.id,
        request_id: request_id
      )
    )

    perform_job(playground_config: {}, playground_config_supplied: true)
  end
end
