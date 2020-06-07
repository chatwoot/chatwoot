require 'rails_helper'

describe ::MessageTemplates::Template::Greeting do
  context 'when this hook is called' do
    let(:conversation) { create(:conversation) }

    it 'creates the email collect messages' do
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.count).to eq(1)
    end
  end
end
