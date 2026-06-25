require 'rails_helper'

describe MessageTemplates::Template::EmailCollect do
  context 'when this hook is called' do
    let(:conversation) { create(:conversation) }

    it 'creates the email collect messages' do
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.count).to eq(2)
    end

    it 'does not create a duplicate pair when invoked again for the same conversation' do
      described_class.new(conversation: conversation).perform
      described_class.new(conversation: conversation).perform

      expect(conversation.messages.where(content_type: :input_email).count).to eq(1)
      expect(conversation.messages.count).to eq(2)
    end
  end
end
