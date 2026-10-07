require 'rails_helper'

RSpec.describe Messages::SearchDataPresenter do
  let(:presenter) { described_class.new(message) }
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) { create(:message, account: account, conversation: conversation, content_type: :voice_call) }

  describe '#search_data' do
    it 'indexes the call transcript as searchable attachment text' do
      create(:call, conversation: conversation, message: message, transcript: 'Refund for order 1234')

      expect(presenter.search_data[:attachments]).to eq([{ transcribed_text: 'Refund for order 1234' }])
    end

    it 'leaves attachments empty when the call has no transcript yet' do
      create(:call, conversation: conversation, message: message)

      expect(presenter.search_data[:attachments]).to be_nil
    end

    it 'keeps attachment transcriptions on non voice_call messages' do
      message.update!(content_type: :text)

      expect(presenter.search_data[:attachments]).to be_nil
    end
  end
end
