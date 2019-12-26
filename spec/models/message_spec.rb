# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:inbox_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  context 'when message is created' do
    let(:message) { build(:message) }

    it 'triggers ::MessageTemplates::HookExecutionService' do
      hook_execution_service = double
      allow(::MessageTemplates::HookExecutionService).to receive(:new).and_return(hook_execution_service)
      allow(hook_execution_service).to receive(:perform).and_return(true)

      message.save!

      expect(::MessageTemplates::HookExecutionService).to have_received(:new).with(message: message)
      expect(hook_execution_service).to have_received(:perform)
    end
  end
end
