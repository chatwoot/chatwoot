require 'rails_helper'

describe ::MessageTemplates::Template::CsatSurvey do
  context 'when this hook is called' do
    let(:conversation) { create(:conversation) }

    it 'creates the out of office messages' do
      described_class.new(conversation: conversation).perform
      expect(conversation.messages.template.count).to eq(1)
      expect(conversation.messages.template.first.content_type).to eq('input_csat')
    end
  end
end
