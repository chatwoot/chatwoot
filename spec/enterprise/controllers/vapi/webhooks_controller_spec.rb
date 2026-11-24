require 'rails_helper'

RSpec.describe 'Vapi::WebhooksController', type: :request do
  let(:account) { create(:account, limits: { 'captain_responses' => 10 }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, status: :pending) }
  let(:secret) { 'hook-secret' }
  let(:vapi_call_id) { "vapi_#{SecureRandom.hex(8)}" }
  let(:twilio_call_sid) { "CA#{SecureRandom.hex(16)}" }
  let(:headers) { { Voice::Captain::WebhookAuth::HEADER => secret, 'Content-Type' => 'application/json' } }

  before do
    account.enable_features!('captain_integration')
    create(:installation_config, name: 'CAPTAIN_VAPI_WEBHOOK_SECRET', value: secret)
    create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
    Voice::Captain::CallSession.new(
      account_id: account.id, inbox_id: inbox.id, conversation_id: conversation.id, contact_id: contact.id, twilio_call_sid: twilio_call_sid
    ).save!(vapi_call_id)
  end

  def post_webhook(message, request_headers: headers)
    post '/vapi/webhook', params: { message: message.merge(call: { id: vapi_call_id }) }.to_json, headers: request_headers
  end

  def tool_call(name, arguments)
    { type: 'tool-calls', toolCallList: [{ id: 'tc_1', type: 'function', function: { name: name, arguments: arguments } }] }
  end

  it 'rejects a request without the shared secret' do
    wrong_headers = headers.merge(Voice::Captain::WebhookAuth::HEADER => 'wrong')

    post_webhook(tool_call('captain--tools--faq_lookup', { query: 'pricing' }), request_headers: wrong_headers)

    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects every request while no secret is set in Super Admin' do
    InstallationConfig.find_by(name: 'CAPTAIN_VAPI_WEBHOOK_SECRET').update!(value: '')

    empty_secret_headers = headers.merge(Voice::Captain::WebhookAuth::HEADER => '')

    post_webhook(tool_call('captain--tools--faq_lookup', { query: 'pricing' }), request_headers: empty_secret_headers)

    expect(response).to have_http_status(:unauthorized)
  end

  it 'returns not found for a call Captain did not start' do
    post '/vapi/webhook', params: { message: { type: 'tool-calls', call: { id: 'unknown' } } }.to_json, headers: headers

    expect(response).to have_http_status(:not_found)
  end

  it 'answers a help-centre question with the FAQs Captain uses in chat' do
    create(:captain_assistant_response, assistant: assistant, account: account, question: 'How much is Pro?', answer: '$19 a month',
                                        status: :approved)
    allow(Captain::AssistantResponse).to receive(:search).and_return(Captain::AssistantResponse.where(assistant: assistant))

    post_webhook(tool_call('captain--tools--faq_lookup', { query: 'pro pricing' }))

    expect(response).to have_http_status(:ok)
    result = response.parsed_body['results'].first
    expect(result['toolCallId']).to eq('tc_1')
    expect(result['result']).to include('$19 a month')
  end

  it 'accepts arguments sent as a JSON string' do
    allow(Captain::AssistantResponse).to receive(:search).and_return(Captain::AssistantResponse.none)

    post_webhook(tool_call('captain--tools--faq_lookup', { query: 'refunds' }.to_json))

    expect(response.parsed_body['results'].first['result']).to eq('No relevant FAQs found for: refunds')
  end

  it 'hands the conversation to agents and moves the caller to their ringing' do
    expect do
      post_webhook(tool_call('captain--tools--handoff', { reason: 'Caller asked for a person', reason_category: 'customer_request' }))
    end.to have_enqueued_job(Voice::Captain::HandoffRedirectJob).with(inbox.id, twilio_call_sid)

    expect(conversation.reload).to be_open
    expect(response.parsed_body['results'].first['result']).to include('handed off')
  end

  it 'adds the summary and transcript to the conversation when the call ends' do
    report = {
      type: 'end-of-call-report',
      endedReason: 'assistant-ended-call',
      analysis: { summary: 'Caller asked about Pro pricing.' },
      artifact: { messages: [
        { role: 'system', message: 'You are...' },
        { role: 'bot', message: 'Hi, how can I help?' },
        { role: 'user', message: 'How much is Pro?' }
      ] }
    }

    expect { post_webhook(report) }.to change { conversation.messages.where(private: true).count }.by(1)

    note = conversation.messages.where(private: true).last
    expect(note.sender).to eq(assistant)
    expect(note.content).to include('Caller asked about Pro pricing.')
    expect(note.content).to include("Captain: Hi, how can I help?\nCaller: How much is Pro?")
    expect(note.content).not_to include('You are...')
  end
end
