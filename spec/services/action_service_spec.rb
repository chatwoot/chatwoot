require 'rails_helper'

describe ::ActionService do
  describe '#resolve_conversation' do
    let(:conversation) { create(:conversation) }
    let(:action_service) { described_class.new(conversation) }

    it 'resolves the conversation' do
      expect(conversation.status).to eq('open')
      action_service.resolve_conversation(nil)
      expect(conversation.reload.status).to eq('resolved')
    end
  end

  describe '#change_priority' do
    let(:conversation) { create(:conversation) }
    let(:action_service) { described_class.new(conversation) }

    it 'changes the priority of the conversation to medium' do
      action_service.change_priority(['medium'])
      expect(conversation.reload.priority).to eq('medium')
    end

    it 'changes the priority of the conversation to nil' do
      action_service.change_priority(['nil'])
      expect(conversation.reload.priority).to be_nil
    end
  end

  # TODO: Expand this test suite
end
