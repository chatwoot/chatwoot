# frozen_string_literal: true

require 'rails_helper'

describe LeadFollowUpListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:user) { create(:user, account: account) }

  describe '#conversation_created' do
    let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
    let(:event) { Events::Base.new('conversation_created', Time.zone.now, conversation: conversation) }

    context 'when there is an active sequence for the inbox' do
      let!(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox, active: true) }

      it 'creates a conversation follow-up' do
        expect do
          listener.conversation_created(event)
        end.to change(ConversationFollowUp, :count).by(1)
      end

      it 'sets the follow-up to active status' do
        listener.conversation_created(event)
        follow_up = conversation.reload.conversation_follow_up
        expect(follow_up.status).to eq('active')
      end

      it 'sets the current_step to 0' do
        listener.conversation_created(event)
        follow_up = conversation.reload.conversation_follow_up
        expect(follow_up.current_step).to eq(0)
      end

      context 'when contact has already sent a message' do
        before do
          create(:message, conversation: conversation, message_type: :incoming, created_at: 1.minute.ago)
        end

        context 'when stop_on_contact_reply is true' do
          before do
            sequence.update!(settings: sequence.settings.merge('stop_on_contact_reply' => true))
          end

          it 'creates the follow-up as completed' do
            listener.conversation_created(event)
            follow_up = conversation.reload.conversation_follow_up
            expect(follow_up.status).to eq('completed')
          end

          it 'stores completion reason' do
            listener.conversation_created(event)
            follow_up = conversation.reload.conversation_follow_up
            expect(follow_up.metadata['completion_reason']).to eq('Contact replied')
          end
        end

        context 'when stop_on_contact_reply is false' do
          before do
            sequence.update!(settings: sequence.settings.merge('stop_on_contact_reply' => false))
          end

          it 'creates the follow-up as active' do
            listener.conversation_created(event)
            follow_up = conversation.reload.conversation_follow_up
            expect(follow_up.status).to eq('active')
          end
        end
      end
    end

    context 'when there is no active sequence' do
      it 'does not create a follow-up' do
        expect do
          listener.conversation_created(event)
        end.not_to change(ConversationFollowUp, :count)
      end
    end

    context 'when inbox is not WhatsApp' do
      let(:web_channel) { create(:channel_widget, account: account) }
      let(:web_inbox) { create(:inbox, channel: web_channel, account: account) }
      let(:web_conversation) { create(:conversation, account: account, inbox: web_inbox, contact: contact) }
      let(:event) { Events::Base.new('conversation_created', Time.zone.now, conversation: web_conversation) }

      it 'does not create a follow-up' do
        expect do
          listener.conversation_created(event)
        end.not_to change(ConversationFollowUp, :count)
      end
    end

    context 'when conversation already has a follow-up' do
      let!(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox, active: true) }
      let!(:existing_follow_up) do
        create(:conversation_follow_up, conversation: conversation, lead_follow_up_sequence: sequence)
      end

      it 'does not create another follow-up' do
        expect do
          listener.conversation_created(event)
        end.not_to change(ConversationFollowUp, :count)
      end
    end
  end

  describe '#message_created' do
    let(:conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
    let(:sequence) { create(:lead_follow_up_sequence, account: account, inbox: whatsapp_inbox, active: true) }
    let!(:follow_up) do
      create(:conversation_follow_up, conversation: conversation, lead_follow_up_sequence: sequence, status: 'active')
    end

    context 'when message is incoming' do
      let(:message) { create(:message, conversation: conversation, message_type: :incoming) }
      let(:event) { Events::Base.new('message_created', Time.zone.now, message: message) }

      context 'when stop_on_contact_reply is true' do
        before do
          sequence.update!(settings: sequence.settings.merge('stop_on_contact_reply' => true))
        end

        it 'marks follow-up as completed' do
          listener.message_created(event)
          expect(follow_up.reload.status).to eq('completed')
        end

        it 'stores completion reason' do
          listener.message_created(event)
          expect(follow_up.reload.metadata['completion_reason']).to eq('Contact replied')
        end
      end

      context 'when stop_on_contact_reply is false' do
        before do
          sequence.update!(settings: sequence.settings.merge('stop_on_contact_reply' => false))
        end

        it 'does not mark as completed' do
          listener.message_created(event)
          expect(follow_up.reload.status).to eq('active')
        end
      end

      context 'when follow-up is already completed' do
        before do
          follow_up.update!(status: 'completed')
        end

        it 'does not change status' do
          listener.message_created(event)
          expect(follow_up.reload.status).to eq('completed')
        end
      end
    end

    context 'when message is outgoing from agent' do
      let(:message) { create(:message, conversation: conversation, message_type: :outgoing, sender: user) }
      let(:event) { Events::Base.new('message_created', Time.zone.now, message: message) }

      it 'resets the sequence to step 0' do
        follow_up.update!(current_step: 2)
        listener.message_created(event)
        expect(follow_up.reload.current_step).to eq(0)
      end

      it 'increments reset_count' do
        listener.message_created(event)
        expect(follow_up.reload.metadata['reset_count']).to eq(1)
      end

      it 'stores reset timestamp' do
        freeze_time do
          listener.message_created(event)
          expect(Time.parse(follow_up.reload.metadata['reset_at'])).to be_within(1.second).of(Time.current)
        end
      end

      it 'updates next_action_at based on first step' do
        listener.message_created(event)
        expect(follow_up.reload.next_action_at).to be_present
      end

      context 'when follow-up is not active' do
        before do
          follow_up.update!(status: 'completed')
        end

        it 'does not reset the sequence' do
          follow_up.update!(current_step: 2)
          listener.message_created(event)
          expect(follow_up.reload.current_step).to eq(2)
        end
      end
    end

    context 'when message is from a bot' do
      let(:message) { create(:message, conversation: conversation, message_type: :outgoing, sender: nil) }
      let(:event) { Events::Base.new('message_created', Time.zone.now, message: message) }

      it 'does not reset the sequence' do
        follow_up.update!(current_step: 2)
        listener.message_created(event)
        expect(follow_up.reload.current_step).to eq(2)
      end
    end

    context 'when conversation has no follow-up' do
      let(:conversation_without_followup) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
      let(:message) { create(:message, conversation: conversation_without_followup, message_type: :incoming) }
      let(:event) { Events::Base.new('message_created', Time.zone.now, message: message) }

      it 'does not raise an error' do
        expect { listener.message_created(event) }.not_to raise_error
      end
    end
  end
end
