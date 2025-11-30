# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoAssignConversationListener do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:incoming_message) { create(:message, conversation: conversation, message_type: :incoming, content: 'Test message') }
  let(:outgoing_message) { create(:message, conversation: conversation, message_type: :outgoing, content: 'Agent reply') }
  let(:listener) { described_class.instance }

  describe '#message_created' do
    context 'when message is incoming' do
      it 'enqueues AutoAssignConversationJob' do
        event = Events::Base.new('message.created', Time.zone.now, { message: incoming_message })

        expect { listener.message_created(event) }
          .to have_enqueued_job(AutoAssignConversationJob)
          .with(conversation.id)
      end
    end

    context 'when message is outgoing' do
      it 'does not enqueue job' do
        event = Events::Base.new('message.created', Time.zone.now, { message: outgoing_message })

        expect { listener.message_created(event) }
          .not_to have_enqueued_job(AutoAssignConversationJob)
      end
    end
  end
end
