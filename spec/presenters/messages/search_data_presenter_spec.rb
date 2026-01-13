require 'rails_helper'

RSpec.describe Messages::SearchDataPresenter do
  let(:presenter) { described_class.new(message) }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, sender: contact) }

  describe '#search_data' do
    let(:expected_data) do
      {
        content: message.content,
        account_id: message.account_id,
        inbox_id: message.inbox_id,
        conversation_id: message.conversation_id,
        message_type: message.message_type,
        private: message.private,
        created_at: message.created_at,
        source_id: message.source_id,
        sender_id: message.sender_id,
        sender_type: message.sender_type,
        conversation: {
          id: conversation.display_id
        }
      }
    end

    it 'returns search index payload with core fields' do
      expect(presenter.search_data).to include(expected_data)
    end

    context 'with attachments' do
      before do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.meta = { 'transcribed_text' => 'Hello world' }
      end

      it 'includes attachment transcriptions' do
        attachments_data = presenter.search_data[:attachments]
        expect(attachments_data).to be_an(Array)
        expect(attachments_data.first).to include(transcribed_text: 'Hello world')
      end
    end

    context 'with email content attributes' do
      before do
        message.update(
          content_attributes: { email: { subject: 'Test Subject' } }
        )
      end

      it 'includes email subject' do
        content_attrs = presenter.search_data[:content_attributes]
        expect(content_attrs[:email][:subject]).to eq('Test Subject')
      end
    end

    context 'with campaign and automation data' do
      before do
        message.update(
          additional_attributes: { 'campaign_id' => '123' },
          content_attributes: { 'automation_rule_id' => '456' }
        )
      end

      it 'includes campaign_id' do
        expect(presenter.search_data[:additional_attributes][:campaign_id]).to eq('123')
      end

      it 'includes automation_rule_id' do
        expect(presenter.search_data[:additional_attributes][:automation_rule_id]).to eq('456')
      end
    end
  end
end
