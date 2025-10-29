require 'rails_helper'

describe Integrations::Dyte::ProcessorService do
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, status: :pending) }
  let(:processor) { described_class.new(account: account, conversation: conversation) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before do
    create(:integrations_hook, :dyte, account: account)
  end

  describe '#create_a_meeting' do
    context 'when the API response is success' do
      before do
        stub_request(:post, 'https://api.dyte.io/v2/meetings')
          .to_return(
            status: 200,
            body: { success: true, data: { id: 'meeting_id' } }.to_json,
            headers: headers
          )
      end

      it 'creates an integration message in the conversation' do
        response = processor.create_a_meeting(agent)
        expect(response[:content]).to eq("#{agent.available_name} has started a meeting")
        expect(conversation.reload.messages.last.content_type).to eq('integrations')
      end
    end

    context 'when the API response is errored' do
      before do
        stub_request(:post, 'https://api.dyte.io/v2/meetings')
          .to_return(
            status: 422,
            body: { success: false, data: { message: 'Title is required' } }.to_json,
            headers: headers
          )
      end

      it 'does not create an integration message in the conversation' do
        response = processor.create_a_meeting(agent)
        expect(response).to eq({ error: { 'data' => { 'message' => 'Title is required' }, 'success' => false }, error_code: 422 })
        expect(conversation.reload.messages.count).to eq(0)
      end
    end
  end

  describe '#add_participant_to_meeting' do
    context 'when the API response is success' do
      before do
        stub_request(:post, 'https://api.dyte.io/v2/meetings/m_id/participants')
          .to_return(
            status: 200,
            body: { success: true, data: { id: 'random_uuid', auth_token: 'json-web-token' } }.to_json,
            headers: headers
          )
      end

      it 'return the authResponse' do
        response = processor.add_participant_to_meeting('m_id', agent)
        expect(response).not_to be_nil
      end
    end
  end
end
