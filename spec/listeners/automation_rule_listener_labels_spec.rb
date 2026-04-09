require 'rails_helper'

describe AutomationRuleListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:label1) { create(:label, account: account, title: 'bug') }
  let(:label2) { create(:label, account: account, title: 'feature') }
  let(:label3) { create(:label, account: account, title: 'urgent') }

  before do
    Current.user = user
  end

  describe 'conversation_updated with label conditions and actions' do
    context 'when label is added and automation rule has label condition' do
      let(:automation_rule) do
        create(:automation_rule,
               event_name: 'conversation_updated',
               account: account,
               conditions: [
                 {
                   attribute_key: 'labels',
                   filter_operator: 'equal_to',
                   values: ['bug'],
                   query_operator: nil
                 }
               ],
               actions: [
                 {
                   action_name: 'add_label',
                   action_params: ['urgent']
                 },
                 {
                   action_name: 'send_message',
                   action_params: ['Bug report received. We will investigate this issue.']
                 }
               ])
      end

      it 'triggers automation when the specified label is added' do
        automation_rule # Create the automation rule
        expect(Messages::MessageBuilder).to receive(:new).and_call_original

        # Add the 'bug' label to trigger the automation
        conversation.add_labels(['bug'])

        # Dispatch the event
        event = Events::Base.new('conversation_updated', Time.zone.now, {
                                   conversation: conversation,
                                   changed_attributes: { label_list: [[], ['bug']] }
                                 })

        listener.conversation_updated(event)

        # Verify the label was added by automation
        expect(conversation.reload.label_list).to include('urgent')

        # Verify a message was sent
        expect(conversation.messages.last.content).to eq('Bug report received. We will investigate this issue.')
      end

      it 'does not trigger automation when a different label is added' do
        automation_rule # Create the automation rule
        expect(Messages::MessageBuilder).not_to receive(:new)

        # Add a different label
        conversation.add_labels(['feature'])

        event = Events::Base.new('conversation_updated', Time.zone.now, {
                                   conversation: conversation,
                                   changed_attributes: { label_list: [[], ['feature']] }
                                 })

        listener.conversation_updated(event)

        # Verify the automation did not run
        expect(conversation.reload.label_list).not_to include('urgent')
      end
    end

    context 'when automation rule has is_present label condition' do
      let(:automation_rule) do
        create(:automation_rule,
               event_name: 'conversation_updated',
               account: account,
               conditions: [
                 {
                   attribute_key: 'labels',
                   filter_operator: 'is_present',
                   values: [],
                   query_operator: nil
                 }
               ],
               actions: [
                 {
                   action_name: 'send_message',
                   action_params: ['Thank you for adding a label to categorize this conversation.']
                 }
               ])
      end

      it 'triggers automation when any label is added to an unlabeled conversation' do
        automation_rule # Create the automation rule
        expect(Messages::MessageBuilder).to receive(:new).and_call_original

        # Add any label to trigger the automation
        conversation.add_labels(['feature'])

        event = Events::Base.new('conversation_updated', Time.zone.now, {
                                   conversation: conversation,
                                   changed_attributes: { label_list: [[], ['feature']] }
                                 })

        listener.conversation_updated(event)

        # Verify a message was sent
        expect(conversation.messages.last.content).to eq('Thank you for adding a label to categorize this conversation.')
      end

      it 'still triggers when labels are removed but conversation still has labels' do
        automation_rule # Create the automation rule
        # Start with multiple labels
        conversation.add_labels(%w[bug feature])
        conversation.reload

        expect(Messages::MessageBuilder).to receive(:new).and_call_original

        # Remove one label but conversation still has labels
        conversation.update_labels(['bug'])

        event = Events::Base.new('conversation_updated', Time.zone.now, {
                                   conversation: conversation,
                                   changed_attributes: { label_list: [%w[bug feature], ['bug']] }
                                 })

        listener.conversation_updated(event)

        # Should still trigger because conversation has labels (is_present condition)
        expect(conversation.messages.last.content).to eq('Thank you for adding a label to categorize this conversation.')
      end

      it 'does not trigger when all labels are removed' do
        automation_rule # Create the automation rule
        # Start with labels
        conversation.add_labels(['bug'])
        conversation.reload

        expect(Messages::MessageBuilder).not_to receive(:new)

        # Remove all labels
        conversation.update_labels([])

        event = Events::Base.new('conversation_updated', Time.zone.now, {
                                   conversation: conversation,
                                   changed_attributes: { label_list: [['bug'], []] }
                                 })

        listener.conversation_updated(event)
      end
    end

    context 'when automation rule has remove_label action' do
      let!(:automation_rule) do
        create(:automation_rule,
               event_name: 'conversation_updated',
               account: account,
               conditions: [
                 {
                   attribute_key: 'labels',
                   filter_operator: 'equal_to',
                   values: ['urgent'],
                   query_operator: nil
                 }
               ],
               actions: [
                 {
                   action_name: 'remove_label',
                   action_params: ['bug']
                 }
               ])
      end

      it 'removes specified labels when condition is met' do
        automation_rule # Create the automation rule
        # Start with both labels
        conversation.add_labels(%w[bug urgent])

        event = Events::Base.new('conversation_updated', Time.zone.now, {
                                   conversation: conversation,
                                   changed_attributes: { label_list: [['bug'], %w[bug urgent]] }
                                 })

        listener.conversation_updated(event)

        # Verify the bug label was removed but urgent remains
        expect(conversation.reload.label_list).to include('urgent')
        expect(conversation.reload.label_list).not_to include('bug')
      end
    end
  end

  describe 'message_created with private note conditions and label actions' do
    let(:baseline_label) { 'automation-baseline' }
    let(:private_note_label) { 'automation-private-note' }

    before do
      inbox.update!(enable_auto_assignment: false)
      clear_enqueued_jobs
      clear_performed_jobs
    end

    let!(:baseline_rule) do
      create(:automation_rule,
             event_name: 'message_created',
             account: account,
             conditions: [
               {
                 attribute_key: 'message_type',
                 filter_operator: 'equal_to',
                 values: ['outgoing'],
                 query_operator: nil
               }
             ],
             actions: [
               {
                 action_name: 'add_label',
                 action_params: [baseline_label]
               }
             ])
    end

    let!(:private_note_rule) do
      create(:automation_rule,
             event_name: 'message_created',
             account: account,
             conditions: [
               {
                 attribute_key: 'message_type',
                 filter_operator: 'equal_to',
                 values: ['outgoing'],
                 query_operator: 'AND'
               },
               {
                 attribute_key: 'private_note',
                 filter_operator: 'equal_to',
                 values: [true],
                 query_operator: nil
               }
             ],
             actions: [
               {
                 action_name: 'add_label',
                 action_params: [private_note_label]
               }
             ])
    end

    it 'keeps message_created behavior for private notes and adds private_note-specific matching' do
      baseline_rule
      private_note_rule

      public_message = create(:message,
                              account: account,
                              conversation: conversation,
                              inbox: inbox,
                              sender: user,
                              message_type: 'outgoing',
                              content: 'public message')
      clear_enqueued_jobs

      listener.message_created(
        Events::Base.new('message_created', Time.zone.now, {
                           message: public_message,
                           changed_attributes: { content: [nil, 'public message'] }
                         })
      )

      expect(conversation.reload.label_list).to include(baseline_label)
      expect(conversation.label_list).not_to include(private_note_label)
      expect(conversation.messages.last.private?).to be(false)

      private_conversation = create(:conversation, account: account, inbox: inbox)
      private_message = create(:message,
                               account: account,
                               conversation: private_conversation,
                               inbox: inbox,
                               sender: user,
                               message_type: 'outgoing',
                               private: true,
                               content: 'private note')
      clear_enqueued_jobs

      listener.message_created(
        Events::Base.new('message_created', Time.zone.now, {
                           message: private_message,
                           changed_attributes: { content: [nil, 'private note'] }
                         })
      )

      expect(private_conversation.reload.label_list).to include(baseline_label, private_note_label)
      expect(private_conversation.messages.last.private?).to be(true)
    end
  end

  describe 'preventing infinite loops' do
    let!(:automation_rule) do
      create(:automation_rule,
             event_name: 'conversation_updated',
             account: account,
             conditions: [
               {
                 attribute_key: 'labels',
                 filter_operator: 'equal_to',
                 values: ['bug'],
                 query_operator: nil
               }
             ],
             actions: [
               {
                 action_name: 'add_label',
                 action_params: ['processed']
               }
             ])
    end

    it 'does not trigger automation when performed by automation rule' do
      automation_rule # Create the automation rule
      conversation.add_labels(['bug'])

      # Simulate event performed by automation rule
      event = Events::Base.new('conversation_updated', Time.zone.now, {
                                 conversation: conversation,
                                 changed_attributes: { label_list: [[], ['bug']] },
                                 performed_by: automation_rule
                               })

      # Should not process the event since it was performed by automation
      expect(AutomationRules::ActionService).not_to receive(:new)

      listener.conversation_updated(event)
    end
  end
end
