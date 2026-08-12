require 'rails_helper'

RSpec.describe Captain::Copilot::ReplySuggestionService do
  subject(:service) do
    described_class.new(
      assistant: assistant,
      conversation_id: conversation.display_id,
      user_id: user.id,
      copilot_thread_id: copilot_thread.id
    )
  end

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: user, assistant: assistant) }
  let(:runner) do
    instance_double(
      Captain::Assistant::AgentRunnerService,
      last_run_result: run_result,
      response_discarded?: false
    )
  end
  let(:run_result) { instance_double(Agents::RunResult) }
  let(:response) do
    {
      'response_parts' => [{ 'text' => "Chatwoot's mascot is Bob the Builder.", 'citation_indexes' => [1] }],
      'response' => "Chatwoot's mascot is Bob the Builder.",
      'reasoning' => 'Found the answer in the approved FAQ.'
    }
  end
  let!(:incoming_message) do
    create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming,
                     content: 'Who is your mascot?')
  end

  before do
    create(:inbox_member, user: user, inbox: inbox)
    incoming_message
    allow(Captain::Assistant::AgentRunnerService).to receive(:new).with(
      hash_including(
        assistant: assistant,
        conversation: conversation,
        source: 'copilot_reply_suggestion',
        read_only: true,
        trace_feature: :copilot,
        stale_response_policy: :public_message
      )
    ).and_return(runner)
    allow(runner).to receive(:generate_response).and_return(response)
    allow(assistant).to receive(:trusted_citation_urls).with(run_result).and_return(1 => 'https://example.com/mascot')
  end

  it 'generates the suggestion with the Assistant Agent Runner in read only mode' do
    service.generate_response

    expect(Captain::Assistant::AgentRunnerService).to have_received(:new).with(
      assistant: assistant,
      conversation: conversation,
      source: 'copilot_reply_suggestion',
      read_only: true,
      trace_feature: :copilot,
      responding_to_message_id: incoming_message.id,
      stale_response_policy: :public_message
    )
    expect(runner).to have_received(:generate_response).with(
      message_history: [{ role: 'user', content: 'Who is your mascot?' }]
    )
  end

  it 'passes the complete ordered conversation to the Assistant Agent Runner' do
    create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :outgoing,
                     content: 'Please try restarting the app.')
    create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming,
                     content: 'It still does not work.')

    service.generate_response

    expect(runner).to have_received(:generate_response).with(
      message_history: [
        { role: 'user', content: 'Who is your mascot?' },
        { role: 'assistant', content: 'Please try restarting the app.' },
        { role: 'user', content: 'It still does not work.' }
      ]
    )
  end

  it 'discards the action without charging when an outgoing reply already exists' do
    create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :outgoing,
                     content: 'Chatwoot uses Bob the Builder as its mascot.')

    expect do
      expect(service.generate_response['discarded']).to be true
    end.not_to(change { account.reload.custom_attributes['captain_responses_usage'].to_i })

    expect(Captain::Assistant::AgentRunnerService).not_to have_received(:new)
    expect(runner).not_to have_received(:generate_response)
    expect(copilot_thread.copilot_messages.last.message['content']).to eq(
      'The conversation changed while Copilot was drafting, so the suggestion was discarded.'
    )
  end

  it 'ignores a trailing resolution activity when the latest public message is incoming' do
    create(
      :message,
      conversation: conversation,
      account: account,
      inbox: inbox,
      message_type: :activity,
      content: 'Conversation was resolved',
      content_attributes: { activity: { type: 'conversation_status_changed', status: 'resolved' } }
    )

    service.generate_response

    expect(runner).to have_received(:generate_response).with(
      message_history: [{ role: 'user', content: 'Who is your mascot?' }]
    )
  end

  it 'persists a reply suggestion with trusted citations' do
    expect do
      service.generate_response
    end.to change(copilot_thread.copilot_messages, :count).by(1)

    message = copilot_thread.copilot_messages.last
    expect(message).to be_assistant
    expect(message.message).to eq(
      'content' => "Chatwoot's mascot is Bob the Builder. [[1](https://example.com/mascot)]",
      'reasoning' => 'Found the answer in the approved FAQ.',
      'reply_suggestion' => true
    )
  end

  it 'increments response usage after persisting the suggestion' do
    expect do
      service.generate_response
    end.to change { account.reload.custom_attributes['captain_responses_usage'].to_i }.by(1)
  end

  it 'charges at most once if the same action is retried after completion' do
    expect do
      service.generate_response
      service.generate_response
    end.to change { account.reload.custom_attributes['captain_responses_usage'].to_i }.by(1)

    expect(copilot_thread.copilot_messages.assistant.count).to eq(1)
  end

  it 'discards a generated response without charging when an agent replies during the run' do
    allow(runner).to receive(:generate_response) do
      create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :outgoing,
                       content: 'An agent handled this message.')
      response
    end

    expect do
      expect(service.generate_response['discarded']).to be true
    end.not_to(change { account.reload.custom_attributes['captain_responses_usage'].to_i })

    message = copilot_thread.copilot_messages.last
    expect(message).to be_assistant
    expect(message.message).to eq(
      'content' => 'The conversation changed while Copilot was drafting, so the suggestion was discarded.'
    )
  end

  it 'persists a terminal message without charging when the runner marks the response as discarded' do
    allow(runner).to receive(:response_discarded?).and_return(true)

    expect do
      expect(service.generate_response['discarded']).to be true
    end.not_to(change { account.reload.custom_attributes['captain_responses_usage'].to_i })

    expect(copilot_thread.copilot_messages.last).to be_assistant
  end

  it 'charges once when a failed attempt is retried successfully' do
    allow(runner).to receive(:generate_response).and_return(
      { 'error' => true, 'reasoning' => 'Temporary model failure.' },
      response
    )

    expect do
      expect { service.generate_response }.to raise_error(
        Captain::Copilot::ReplySuggestionService::GenerationError,
        'Temporary model failure.'
      )
    end.not_to(change { account.reload.custom_attributes['captain_responses_usage'].to_i })

    expect do
      service.generate_response
    end.to change { account.reload.custom_attributes['captain_responses_usage'].to_i }.by(1)

    expect(copilot_thread.copilot_messages.assistant.count).to eq(1)
  end

  it 'does not use a conversation the user cannot access' do
    custom_role = create(:custom_role, account: account, permissions: [])
    account.account_users.find_by!(user: user).update!(role: :agent, custom_role: custom_role)

    expect { service.generate_response }.to raise_error(ActiveRecord::RecordNotFound, 'Conversation not found')
    expect(runner).not_to have_received(:generate_response)
  end

  it 'does not persist an Agent Runner error as a customer reply' do
    allow(runner).to receive(:generate_response).and_return(
      'error' => true,
      'reasoning' => 'The model request failed.'
    )

    expect { service.generate_response }.to raise_error(
      Captain::Copilot::ReplySuggestionService::GenerationError,
      'The model request failed.'
    )
    expect(copilot_thread.copilot_messages).to be_empty
  end
end
