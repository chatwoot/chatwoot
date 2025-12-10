# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::CreateGroupJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) do
    create(:inbox, account: account, auto_assignment_config: {
             'assignment_type' => 'group'
           })
  end
  let(:agent) { create(:user, account: account, phone_number: '+1234567890') }
  let(:contact) { create(:contact, account: account, phone_number: '+9876543210') }
  let(:conversation) { create(:conversation, inbox: inbox, assignee: agent, contact: contact) }

  describe '#perform' do
    it 'calls Whatsapp::GroupService to create a group' do
      service = instance_double(Whatsapp::GroupService)
      allow(Whatsapp::GroupService).to receive(:new).with(conversation: conversation).and_return(service)
      expect(service).to receive(:create_group)

      described_class.new.perform(conversation.id)
    end

    context 'when conversation does not exist' do
      it 'does not raise error' do
        expect do
          described_class.new.perform(999_999)
        end.not_to raise_error
      end
    end

    it 'enqueues the job' do
      expect do
        described_class.perform_later(conversation.id)
      end.to have_enqueued_job(described_class).with(conversation.id)
    end
  end
end
