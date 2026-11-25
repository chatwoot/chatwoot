require 'rails_helper'

RSpec.describe Macros::ExecutionService, type: :service do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:user) { create(:user, account: account) }
  let(:macro) { create(:macro, account: account) }
  let(:service) { described_class.new(macro, conversation, user) }

  before do
    create(:inbox_member, user: user, inbox: conversation.inbox)
  end

  describe '#perform' do
    context 'when actions are present' do
      before do
        allow(macro).to receive(:actions).and_return([
                                                       { action_name: 'assign_agent', action_params: ['self'] },
                                                       { action_name: 'add_private_note', action_params: ['Test note'] },
                                                       { action_name: 'send_message', action_params: ['Test message'] },
                                                       { action_name: 'send_attachment', action_params: [1, 2] },
                                                       { action_name: 'send_webhook_event', action_params: ['https://example.com/webhook'] }
                                                     ])
      end

      it 'executes the actions' do
        expect(service).to receive(:assign_agent).with(['self']).and_call_original
        expect(service).to receive(:add_private_note).with(['Test note']).and_call_original
        expect(service).to receive(:send_message).with(['Test message']).and_call_original
        expect(service).to receive(:send_attachment).with([1, 2]).and_call_original

        service.perform
      end

      context 'when an action raises an error' do
        let(:exception_tracker) { instance_spy(ChatwootExceptionTracker) }

        before do
          allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
        end

        it 'captures the exception' do
          allow(service).to receive(:assign_agent).and_raise(StandardError.new('Random error'))
          expect(exception_tracker).to receive(:capture_exception)

          service.perform
        end
      end
    end

    # A refused save leaves its attributes dirty on the record, and the next
    # action would save them too. An inbox that prevents assignment takeover is
    # one way to get here; any rejected save is another.
    context 'when an action is refused mid-macro' do
      let(:owner) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: owner, inbox: conversation.inbox)
        conversation.update!(assignee: owner)
        conversation.inbox.update!(prevent_assignment_takeover: true)
        allow(macro).to receive(:actions).and_return([
                                                       { action_name: 'assign_agent', action_params: ['self'] },
                                                       { action_name: 'change_status', action_params: ['resolved'] }
                                                     ])
      end

      it 'still runs the actions that follow it' do
        service.perform

        expect(conversation.reload.assignee).to eq(owner)
        expect(conversation.reload.status).to eq('resolved')
      end
    end
  end

  describe '#assign_team' do
    let(:team) { create(:team, account: account, allow_auto_assign: false) }

    context 'when team_id is nil' do
      it 'unassigns the team from the conversation' do
        conversation.update!(team_id: team.id)
        service.send(:assign_team, ['nil'])
        expect(conversation.reload.team).to be_nil
      end
    end
  end

  describe '#assign_agent' do
    context 'when agent_ids contains self' do
      it 'updates the conversation assignee to the current user' do
        service.send(:assign_agent, ['self'])
        expect(conversation.reload.assignee).to eq(user)
      end
    end

    context 'when agent_ids does not contain self' do
      let(:other_user) { create(:user, account: account) }

      before do
        create(:inbox_member, user: other_user, inbox: conversation.inbox)
      end

      it 'calls the super method' do
        service.send(:assign_agent, [other_user.id])
        expect(conversation.reload.assignee).to eq(other_user)
      end
    end

    context 'when agent_ids contains nil' do
      it 'unassigns the conversation' do
        conversation.update!(assignee: user)
        service.send(:assign_agent, ['nil'])
        expect(conversation.reload.assignee).to be_nil
      end
    end
  end

  describe '#add_private_note' do
    context 'when conversation is not a tweet' do
      it 'creates a new private message' do
        expect do
          service.send(:add_private_note, ['Test private note'])
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.content).to eq('Test private note')
        expect(message.private).to be(true)
      end
    end

    context 'when conversation is a tweet' do
      before { allow(service).to receive(:conversation_a_tweet?).and_return(true) }

      it 'does not create a new message' do
        expect do
          service.send(:add_private_note, ['Test private note'])
        end.not_to change(Message, :count)
      end
    end
  end

  describe '#send_message' do
    context 'when conversation is not a tweet' do
      it 'creates a new public message' do
        expect do
          service.send(:send_message, ['Test message'])
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.content).to eq('Test message')
        expect(message.private).to be(false)
      end
    end

    context 'when conversation is a tweet' do
      before { allow(service).to receive(:conversation_a_tweet?).and_return(true) }

      it 'does not create a new message' do
        expect do
          service.send(:send_message, ['Test message'])
        end.not_to change(Message, :count)
      end
    end
  end

  describe '#send_attachment' do
    before do
      macro.files.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      macro.save!
    end

    context 'when conversation is not a tweet and macro has files attached' do
      before { allow(service).to receive(:conversation_a_tweet?).and_return(false) }

      it 'creates a new message with attachments' do
        expect do
          service.send(:send_attachment, [macro.files.first.blob_id])
        end.to change(Message, :count).by(1)

        message = Message.last
        expect(message.attachments).to be_present
      end

      it 'only sends macro files when stored actions also reference another account attachment' do
        foreign_message = create(:message, :with_attachment)
        foreign_blob = foreign_message.attachments.first.file.blob
        own_blob = macro.files.first.blob
        macro.update!(actions: [{ action_name: 'send_attachment', action_params: [own_blob.id, foreign_blob.id] }])

        service.perform

        expect(conversation.messages.last.attachments.map { |attachment| attachment.file.blob_id }).to eq([own_blob.id])
      end

      it 'does not send another account attachment when no requested blob belongs to the macro' do
        foreign_message = create(:message, :with_attachment)
        foreign_blob = foreign_message.attachments.first.file.blob
        macro.update!(actions: [{ action_name: 'send_attachment', action_params: [foreign_blob.id] }])

        expect { service.perform }.not_to change(conversation.messages, :count)
      end

      it 'does not send files belonging to another macro in the same account' do
        other_macro = create(:macro, account: account)
        other_macro.files.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        macro.update!(actions: [{ action_name: 'send_attachment', action_params: [other_macro.files.first.blob_id] }])

        expect { service.perform }.not_to change(conversation.messages, :count)
      end
    end

    context 'when conversation is a tweet or macro has no files attached' do
      before { allow(service).to receive(:conversation_a_tweet?).and_return(true) }

      it 'does not create a new message' do
        expect do
          service.send(:send_attachment, [macro.files.first.blob_id])
        end.not_to change(Message, :count)
      end
    end
  end

  describe '#send_webhook_event' do
    it 'sends a webhook event' do
      expect(WebhookJob).to receive(:perform_later)
      service.send(:send_webhook_event, ['https://example.com/webhook'])
    end

    it 'includes the macro and the executing user in the payload' do
      expect(WebhookJob).to receive(:perform_later) do |url, payload|
        expect(url).to eq('https://example.com/webhook')
        expect(payload[:event]).to eq('macro.executed')
        expect(payload[:macro]).to eq({ id: macro.id, name: macro.name })
        expect(payload[:executed_by]).to eq(user.webhook_data)
      end

      service.send(:send_webhook_event, ['https://example.com/webhook'])
    end

    it 'sends the conversation as webhook_data by default' do
      expect(service.send(:webhook_conversation_data)).to eq(conversation.webhook_data)
    end

    # An extension narrows what the macro sends by overriding webhook_conversation_data alone.
    it 'builds the conversation part of the payload from webhook_conversation_data' do
      allow(service).to receive(:webhook_conversation_data).and_return({ marker: 951 })

      expect(WebhookJob).to receive(:perform_later) do |_url, payload|
        expect(payload).to include(marker: 951, event: 'macro.executed', macro: { id: macro.id, name: macro.name })
        expect(payload).not_to have_key(:id)
      end

      service.send(:send_webhook_event, ['https://example.com/webhook'])
    end
  end

  describe 'conversation variables in the text of an action' do
    it 'reads the live conversation and leaves the automation snapshot out of it' do
      user.update!(name: 'john doe')
      note_text = 'Antes=[{{conversation.before.assignee.name}}] Agora=[{{conversation.assignee.name}}]'
      allow(macro).to receive(:actions).and_return([
                                                     { action_name: 'assign_agent', action_params: ['self'] },
                                                     { action_name: 'add_private_note', action_params: [note_text] }
                                                   ])

      service.perform

      expect(conversation.reload.messages.where(private: true).last.content).to eq 'Antes=[] Agora=[John Doe]'
    end
  end
end
