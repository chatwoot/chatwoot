# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoLabelListener do
  include ActiveJob::TestHelper

  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) { create(:message, conversation: conversation, message_type: :incoming, content: 'Test message') }

  let(:event) do
    Events::Base.new('message.created', Time.zone.now, { message: message })
  end

  before do
    # Create enough messages to meet the threshold
    create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Customer message')
  end

  describe '#message_created' do
    context 'when all conditions are met' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 3 })
      end

      it 'enqueues AutoLabelJob' do
        expect do
          listener.message_created(event)
        end.to have_enqueued_job(Labels::AutoLabelJob).with(conversation.id)
      end
    end

    context 'when message is outgoing' do
      let(:message) { create(:message, conversation: conversation, message_type: :outgoing, content: 'Agent reply') }

      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 3 })
      end

      it 'does not enqueue job' do
        expect do
          listener.message_created(event)
        end.not_to have_enqueued_job(Labels::AutoLabelJob)
      end
    end

    context 'when auto_label_enabled is false' do
      before do
        account.update!(settings: { auto_label_enabled: false })
      end

      it 'does not enqueue job' do
        expect do
          listener.message_created(event)
        end.not_to have_enqueued_job(Labels::AutoLabelJob)
      end
    end

    context 'when auto_label_enabled is not set' do
      before do
        account.update!(settings: {})
      end

      it 'does not enqueue job' do
        expect do
          listener.message_created(event)
        end.not_to have_enqueued_job(Labels::AutoLabelJob)
      end
    end

    context 'when conversation already has labels' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 3 })
        conversation.label_list.add('Existing Label')
        conversation.save!
      end

      it 'does not enqueue job' do
        expect do
          listener.message_created(event)
        end.not_to have_enqueued_job(Labels::AutoLabelJob)
      end
    end

    context 'when message threshold is not met' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 5 })
        conversation.messages.destroy_all
        create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Message')
      end

      it 'does not enqueue job' do
        expect do
          listener.message_created(event)
        end.not_to have_enqueued_job(Labels::AutoLabelJob)
      end
    end

    context 'when message threshold is exactly met' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 3 })
        conversation.messages.destroy_all
        create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Message')
      end

      it 'enqueues job' do
        expect do
          listener.message_created(event)
        end.to have_enqueued_job(Labels::AutoLabelJob).with(conversation.id)
      end
    end

    context 'when message threshold is exceeded' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 3 })
        conversation.messages.destroy_all
        create_list(:message, 5, conversation: conversation, message_type: :incoming, content: 'Message')
      end

      it 'enqueues job' do
        expect do
          listener.message_created(event)
        end.to have_enqueued_job(Labels::AutoLabelJob).with(conversation.id)
      end
    end

    context 'when threshold is not configured' do
      before do
        account.update!(settings: { auto_label_enabled: true })
        conversation.messages.destroy_all
        create_list(:message, 3, conversation: conversation, message_type: :incoming, content: 'Message')
      end

      it 'uses default threshold of 3 and enqueues job' do
        expect do
          listener.message_created(event)
        end.to have_enqueued_job(Labels::AutoLabelJob).with(conversation.id)
      end
    end

    context 'with custom threshold' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 7 })
        conversation.messages.destroy_all
        create_list(:message, 7, conversation: conversation, message_type: :incoming, content: 'Message')
      end

      it 'respects custom threshold' do
        expect do
          listener.message_created(event)
        end.to have_enqueued_job(Labels::AutoLabelJob).with(conversation.id)
      end
    end

    context 'with mixed incoming and outgoing messages' do
      before do
        account.update!(settings: { auto_label_enabled: true, auto_label_message_threshold: 3 })
        conversation.messages.destroy_all
        create(:message, conversation: conversation, message_type: :incoming, content: 'Message 1')
        create(:message, conversation: conversation, message_type: :outgoing, content: 'Reply 1')
        create(:message, conversation: conversation, message_type: :incoming, content: 'Message 2')
        create(:message, conversation: conversation, message_type: :outgoing, content: 'Reply 2')
        create(:message, conversation: conversation, message_type: :incoming, content: 'Message 3')
      end

      it 'only counts incoming messages for threshold' do
        expect(conversation.messages.incoming.count).to eq(3)

        expect do
          listener.message_created(event)
        end.to have_enqueued_job(Labels::AutoLabelJob).with(conversation.id)
      end
    end
  end
end
