require 'rails_helper'

RSpec.describe ConversationMonitors::Evaluator do
  subject(:evaluate) { -> { described_class.new(work.reload).perform } }

  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account) }
  let(:second) { create(:conversation_monitor, account: account, condition: 'Mentions WhatsApp BSUID') }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) { create(:message, account: account, conversation: conversation, content: 'Please refund my order') }
  let(:work) { ConversationMonitors::WorkItem.find_by!(conversation_id: conversation.id) }
  let(:answers) { { monitor.id.to_s => { type: 'noul', noul: 0.95 }, second.id.to_s => { type: 'noul', noul: 0.05 } } }
  let(:response_body) { { model: 'jev-1.13.0', answers: answers, usage: { input_tokens: 100 } } }
  let(:endpoint) { ConversationMonitors::JevClient::ENDPOINT }

  around { |example| with_modified_env(TYPESAFE_API_KEY: 'test-key') { example.run } }

  before do
    account.enable_features!('reports', 'conversation_monitors')
    monitor
    second
    message
    work.update!(due_at: Time.current)
    stub_request(:post, endpoint).to_return(status: 200, body: response_body.to_json)
  end

  it 'batches independent questions and counts a conversation only once per monitor' do
    evaluate.call
    expect(monitor.evaluations.sole.status).to eq('matched')
    expect(second.evaluations.sole.status).to eq('unmatched')
    work.update!(due_at: Time.current)
    evaluate.call

    expect(monitor.evaluations.count).to eq(1)
    expect(WebMock).to have_requested(:post, endpoint).once
    expect(work.reload.due_at).to be_nil
  end

  it 'reevaluates negatives on new incoming messages without calling already matched conditions' do
    evaluate.call
    create(:message, account: account, conversation: conversation, content: 'Also, what is my WhatsApp BSUID?')
    work.reload.update!(due_at: Time.current)
    stub_request(:post, endpoint).with { |request| JSON.parse(request.body)['questions'].keys == [second.id.to_s] }
                                 .to_return(status: 200, body: response_body.deep_merge(answers: { second.id.to_s => { type: 'noul',
                                                                                                                       noul: 0.9 } }).to_json)
    evaluate.call

    expect(second.evaluations.sole.status).to eq('matched')
    expect(monitor.evaluations.sole.status).to eq('matched')
  end

  it 'keeps an input arriving during a provider request due for another evaluation' do
    stub_request(:post, endpoint).to_return do
      create(:message, account: account, conversation: conversation, content: 'Another question')
      { status: 200, body: response_body.to_json }
    end
    evaluate.call

    expect(work.reload.revision).to be > work.processed_revision
    expect(work.due_at).to be_present
    expect(work.lease_token).to be_nil
  end

  it 'rejects an in-flight positive result after redaction' do
    stub_request(:post, endpoint).to_return do
      message.update!(content: 'Deleted', content_attributes: { deleted: true })
      { status: 200, body: response_body.to_json }
    end
    evaluate.call

    expect(monitor.evaluations.where(status: 'matched')).not_to exist
    expect(work.reload.due_at).to be_present
  end

  it 'preserves valid answers while retrying missing answers' do
    stub_request(:post, endpoint).to_return(status: 200, body: response_body.merge(answers: answers.except(second.id.to_s)).to_json)
    evaluate.call

    expect(monitor.evaluations.sole.status).to eq('matched')
    expect(second.evaluations.sole.error_code).to eq('invalid_response')
    expect(work.reload.due_at).to be_present
  end

  it 'honors provider retry-after without recording negatives' do
    stub_request(:post, endpoint).to_return(status: 429, headers: { 'Retry-After' => '120' })
    evaluate.call

    expect(work.reload.due_at).to be >= 119.seconds.from_now
    expect(monitor.evaluations.sole.status).to eq('error')
    expect(monitor.evaluations.sole.error_code).to eq('provider_busy')
  end

  it 'leaves invalid credentials visible without endlessly retrying' do
    stub_request(:post, endpoint).to_return(status: 401)
    evaluate.call

    expect(work.reload.due_at).to be_nil
    expect(monitor.evaluations.sole.error_code).to eq('credentials_invalid')
  end

  it 'preserves due work while collection is disabled' do
    account.disable_features!('conversation_monitors')
    evaluate.call

    expect(WebMock).not_to have_requested(:post, endpoint)
    expect(work.reload.due_at).to be_present
  end

  it 'does not restore a monitor archived during evaluation' do
    stub_request(:post, endpoint).to_return do
      monitor.update!(archived_at: Time.current)
      { status: 200, body: response_body.to_json }
    end
    evaluate.call

    expect(monitor.evaluations).not_to exist
    expect(second.evaluations.sole.status).to eq('unmatched')
  end

  it 'does not dispatch more batches after the feature is disabled during a provider call' do
    create_list(:conversation_monitor, 7, account: account)
    stub_request(:post, endpoint).to_return do |request|
      account.disable_features!('conversation_monitors')
      values = JSON.parse(request.body)['questions'].keys.index_with { |_id| { type: 'noul', noul: 0.9 } }
      { status: 200, body: response_body.merge(answers: values).to_json }
    end
    evaluate.call

    expect(WebMock).to have_requested(:post, endpoint).once
    expect(work.reload.due_at).to be_present
  end

  it 'preserves existing matches and skips future incoming messages when all monitors are paused' do
    evaluate.call
    monitor.update!(paused_at: Time.current)
    second.update!(paused_at: Time.current)
    revision = work.reload.revision
    create(:message, account: account, conversation: conversation, content: 'New incoming message after pause')
    fresh = create(:conversation, account: account)
    create(:message, account: account, conversation: fresh, content: 'New conversation after pause')
    evaluate.call

    expect(work.reload.revision).to eq(revision)
    expect(ConversationMonitors::WorkItem.where(conversation: fresh)).not_to exist
    expect(monitor.evaluations.sole.status).to eq('matched')
    expect(second.evaluations.sole.status).to eq('unmatched')
    expect(WebMock).to have_requested(:post, endpoint).once
  end

  it 'excludes paused conditions while continuing other monitors on the same conversation' do
    monitor.update!(paused_at: Time.current)
    evaluate.call

    expect(WebMock).to have_requested(:post, endpoint).with { |request| JSON.parse(request.body)['questions'].keys == [second.id.to_s] }.once
    expect(monitor.evaluations).not_to exist
    expect(second.evaluations.sole.status).to eq('unmatched')
  end

  it 'discards a provider result if the monitor was paused during the request' do
    stub_request(:post, endpoint).to_return do
      monitor.update!(paused_at: Time.current)
      { status: 200, body: response_body.to_json }
    end
    evaluate.call

    expect(monitor.evaluations).not_to exist
    expect(second.evaluations.sole.status).to eq('unmatched')
  end

  it 'does not send a later batch for monitors paused during an earlier request' do
    monitors = create_list(:conversation_monitor, 7, account: account)
    stub_request(:post, endpoint).to_return do |request|
      monitors.each { |entry| entry.update!(paused_at: Time.current) }
      values = JSON.parse(request.body)['questions'].keys.index_with { { type: 'noul', noul: 0.9 } }
      { status: 200, body: response_body.merge(answers: values).to_json }
    end
    evaluate.call

    expect(WebMock).to have_requested(:post, endpoint).once
    expect(ConversationMonitors::Evaluation.where(monitor: monitors)).not_to exist
  end
end
