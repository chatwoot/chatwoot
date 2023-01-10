require 'rails_helper'
describe AutomationRuleListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, identifier: '123') }
  let(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let!(:automation_rule) { create(:automation_rule, account: account, name: 'Test Automation Rule') }
  let(:team) { create(:team, account: account) }
  let(:user_1) { create(:user, role: 0) }
  let(:user_2) { create(:user, role: 0) }

  before do
    create(:custom_attribute_definition,
           attribute_key: 'customer_type',
           account: account,
           attribute_model: 'contact_attribute',
           attribute_display_type: 'list',
           attribute_values: %w[regular platinum gold])
    create(:custom_attribute_definition,
           attribute_key: 'priority',
           account: account,
           attribute_model: 'conversation_attribute',
           attribute_display_type: 'list',
           attribute_values: %w[P0 P1 P2])
    create(:custom_attribute_definition,
           attribute_key: 'cloud_customer',
           attribute_display_type: 'checkbox',
           account: account,
           attribute_model: 'contact_attribute')
    create(:team_member, user: user_1, team: team)
    create(:team_member, user: user_2, team: team)
    create(:inbox_member, user: user_1, inbox: inbox)
    create(:inbox_member, user: user_2, inbox: inbox)
    create(:account_user, user: user_2, account: account)
    create(:account_user, user: user_1, account: account)

    conversation.resolved!
    automation_rule.update!(actions:
                                      [
                                        {
                                          'action_name' => 'send_email_to_team', 'action_params' => [{
                                            'message' => 'Please pay attention to this conversation, its from high priority customer',
                                            'team_ids' => [team.id]
                                          }]
                                        },
                                        { 'action_name' => 'assign_team', 'action_params' => [team.id] },
                                        { 'action_name' => 'add_label', 'action_params' => %w[support priority_customer] },
                                        { 'action_name' => 'send_webhook_event', 'action_params' => ['https://www.example.com'] },
                                        { 'action_name' => 'assign_agent', 'action_params' => [user_1.id] },
                                        { 'action_name' => 'send_email_transcript', 'action_params' => ['new_agent@example.com'] },
                                        { 'action_name' => 'mute_conversation', 'action_params' => nil },
                                        { 'action_name' => 'change_status', 'action_params' => ['snoozed'] },
                                        { 'action_name' => 'send_message', 'action_params' => ['Send this message.'] },
                                        { 'action_name' => 'send_attachment' }
                                      ])
    file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    automation_rule.files.attach(file)
    automation_rule.save!
  end

  describe '#conversation_updated with contacts attributes' do
    before do
      conversation.contact.update!(custom_attributes: { customer_type: 'platinum', signed_in_at: '2022-01-19' },
                                   additional_attributes: { 'company': 'Marvel' })

      automation_rule.update!(
        event_name: 'conversation_updated',
        name: 'Call actions conversation updated',
        description: 'Add labels, assign team after conversation updated',
        conditions: [
          {
            attribute_key: 'company',
            filter_operator: 'equal_to',
            values: ['Marvel'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'customer_type',
            filter_operator: 'equal_to',
            values: ['platinum'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'inbox_id',
            filter_operator: 'equal_to',
            values: [inbox.id],
            query_operator: nil
          }.with_indifferent_access
        ]
      )
    end

    let!(:event) do
      Events::Base.new('conversation_updated', Time.zone.now, { conversation: conversation })
    end

    context 'when rule matches with additional_attributes and custom_attributes' do
      it 'triggers automation rule to assign team' do
        expect(conversation.team_id).not_to eq(team.id)

        listener.conversation_updated(event)

        conversation.reload
        expect(conversation.team_id).to eq(team.id)
      end

      it 'triggers automation rule to add label and assign best agents' do
        expect(conversation.labels).to eq([])
        expect(conversation.assignee).to be_nil

        listener.conversation_updated(event)

        conversation.reload
        expect(conversation.labels.pluck(:name)).to contain_exactly('support', 'priority_customer')
        expect(conversation.assignee).to eq(user_1)
      end

      it 'triggers automation rule send email transcript to the mentioned email' do
        mailer = double

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)

        listener.conversation_updated(event)

        conversation.reload

        allow(mailer).to receive(:conversation_transcript)
      end

      it 'triggers automation rule send message to the contacts' do
        expect(conversation.messages).to be_empty

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)

        listener.conversation_updated(event)

        conversation.reload

        expect(conversation.messages.first.content).to eq('Send this message.')
      end

      it 'triggers automation rule to mute conversation' do
        expect(conversation).not_to be_muted

        listener.conversation_updated(event)

        conversation.reload
        expect(conversation).to be_muted
      end

      it 'triggers automation_rule with contact standard attributes' do
        automation_rule.update!(
          conditions: [
            {
              attribute_key: 'email',
              filter_operator: 'contains',
              values: ['example.com'],
              query_operator: 'AND'
            }.with_indifferent_access,
            {
              attribute_key: 'customer_type',
              filter_operator: 'equal_to',
              values: ['platinum'],
              query_operator: nil
            }.with_indifferent_access
          ]
        )
        expect(conversation.team_id).not_to eq(team.id)

        listener.conversation_updated(event)

        conversation.reload
        expect(conversation.team_id).to eq(team.id)
      end
    end

    context 'when inbox condition does not match' do
      let!(:inbox_1) { create(:inbox, account: account) }
      let!(:event) do
        Events::Base.new('conversation_updated', Time.zone.now, { conversation: conversation })
      end

      before do
        automation_rule.update!(
          event_name: 'conversation_updated',
          name: 'Call actions conversation updated',
          description: 'Add labels, assign team after conversation updated',
          conditions: [
            {
              attribute_key: 'inbox_id',
              filter_operator: 'equal_to',
              values: [inbox_1.id],
              query_operator: nil
            }.with_indifferent_access
          ]
        )
      end

      it 'triggers automation rule would not send message to the contacts' do
        expect(conversation.messages.count).to eq(0)
        expect(conversation.messages).to be_empty

        listener.conversation_updated(event)

        conversation.reload

        expect(conversation.messages.count).to eq(0)
      end
    end
  end

  describe '#conversation_updated' do
    before do
      automation_rule.update!(
        event_name: 'conversation_updated',
        name: 'Call actions conversation updated',
        description: 'Add labels, assign team after conversation updated'
      )
    end

    let!(:event) do
      Events::Base.new('conversation_updated', Time.zone.now, { conversation: conversation })
    end

    context 'when rule matches' do
      it 'triggers automation rule to assign team' do
        expect(conversation.team_id).not_to eq(team.id)
        listener.conversation_updated(event)
        conversation.reload

        expect(conversation.team_id).to eq(team.id)
      end

      it 'triggers automation rule to add label' do
        expect(conversation.labels).to eq([])
        listener.conversation_updated(event)
        conversation.reload

        expect(conversation.labels.pluck(:name)).to contain_exactly('support', 'priority_customer')
      end

      it 'triggers automation rule to assign best agents' do
        expect(conversation.assignee).to be_nil
        listener.conversation_updated(event)
        conversation.reload

        expect(conversation.assignee).to eq(user_1)
      end

      it 'triggers automation rule send email transcript to the mentioned email' do
        mailer = double
        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)
        listener.conversation_updated(event)
        conversation.reload

        allow(mailer).to receive(:conversation_transcript)
      end

      it 'triggers automation rule send email to the team' do
        message_delivery = instance_double(ActionMailer::MessageDelivery)

        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation).with(
          conversation, team,
          'Please pay attention to this conversation, its from high priority customer'
        ).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now)

        listener.conversation_updated(event)
      end

      it 'triggers automation rule send message to the contacts' do
        expect(conversation.messages).to be_empty
        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)
        listener.conversation_updated(event)
        conversation.reload

        expect(conversation.messages.first.content).to eq('Send this message.')
      end
    end

    context 'when rule matches based on custom_attributes' do
      before do
        conversation.update!(custom_attributes: { priority: 'P2' })
        conversation.contact.update!(custom_attributes: { cloud_customer: false })

        automation_rule.update!(
          event_name: 'conversation_updated',
          name: 'Priority customer check',
          description: 'Add labels, assign team after conversation updated',
          conditions: [
            {
              attribute_key: 'priority',
              filter_operator: 'equal_to',
              values: ['P2'],
              custom_attribute_type: 'conversation_attribute',
              query_operator: 'AND'
            }.with_indifferent_access,
            {
              attribute_key: 'cloud_customer',
              filter_operator: 'equal_to',
              values: [false],
              custom_attribute_type: 'contact_attribute',
              query_operator: nil
            }.with_indifferent_access
          ]
        )
      end

      it 'triggers automation rule to assign team' do
        expect(conversation.team_id).not_to eq(team.id)
        listener.conversation_updated(event)
        conversation.reload

        expect(conversation.team_id).to eq(team.id)
      end

      it 'triggers automation rule to add label' do
        expect(conversation.labels).to eq([])
        listener.conversation_updated(event)
        conversation.reload

        expect(conversation.labels.pluck(:name)).to contain_exactly('support', 'priority_customer')
      end
    end

    context 'when conditions based on attribute_changed' do
      before do
        automation_rule.update!(
          event_name: 'conversation_updated',
          name: 'Call actions conversation updated when company changed from DC to Marvel',
          description: 'Add labels, assign team after conversation updated',
          conditions: [
            {
              attribute_key: 'company',
              filter_operator: 'attribute_changed',
              values: { from: ['DC'], to: ['Marvel'] },
              query_operator: 'AND'
            }.with_indifferent_access,
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: ['snoozed'],
              query_operator: nil
            }.with_indifferent_access
          ]
        )
        conversation.update(status: :snoozed)
      end

      let!(:event) do
        Events::Base.new('conversation_updated', Time.zone.now, { conversation: conversation, changed_attributes: {
                           company: %w[DC Marvel]
                         } })
      end

      context 'when rule matches' do
        it 'triggers automation rule to assign team' do
          expect(conversation.team_id).not_to eq(team.id)

          listener.conversation_updated(event)

          conversation.reload
          expect(conversation.team_id).to eq(team.id)
        end

        it 'triggers automation rule to assign team with OR operator' do
          conversation.update(status: :open)
          automation_rule.update!(
            conditions: [
              {
                attribute_key: 'company',
                filter_operator: 'attribute_changed',
                values: { from: ['DC'], to: ['Marvel'] },
                query_operator: 'OR'
              }.with_indifferent_access,
              {
                attribute_key: 'status',
                filter_operator: 'equal_to',
                values: ['snoozed'],
                query_operator: nil
              }.with_indifferent_access
            ]
          )

          expect(conversation.team_id).not_to eq(team.id)

          listener.conversation_updated(event)

          conversation.reload
          expect(conversation.team_id).to eq(team.id)
        end
      end

      context 'when rule doesnt match' do
        it 'when automation rule is triggered it will not assign team' do
          conversation.update(status: :open)

          expect(conversation.team_id).not_to eq(team.id)

          listener.conversation_updated(event)

          conversation.reload
          expect(conversation.team_id).not_to eq(team.id)
        end

        it 'when automation rule is triggers, it will not assign team on attribute_changed values' do
          conversation.update(status: :snoozed)
          event = Events::Base.new('conversation_updated', Time.zone.now, { conversation: conversation,
                                                                            changed_attributes: { company: %w[Marvel DC] } })

          expect(conversation.team_id).not_to eq(team.id)

          listener.conversation_updated(event)

          conversation.reload
          expect(conversation.team_id).not_to eq(team.id)
        end
      end
    end
  end

  describe '#message_created event based on case in-sensitive filter' do
    before do
      automation_rule.update!(
        event_name: 'message_created',
        name: 'Call actions message created based on case in-sensitive filter',
        description: 'Add labels, assign team after message created',
        conditions: [
          { 'values': ['KYC'], 'attribute_key': 'content', 'query_operator': nil, 'filter_operator': 'contains' }
        ]
      )
    end

    let!(:message) { create(:message, account: account, conversation: conversation, message_type: 'incoming', content: 'KyC message') }
    let!(:message_2) { create(:message, account: account, conversation: conversation, message_type: 'incoming', content: 'SALE') }

    let!(:event) do
      Events::Base.new('message_created', Time.zone.now, { conversation: conversation, message: message })
    end

    it 'triggers automation rule on contains filter' do
      expect(conversation.labels).to eq([])
      expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)
      listener.message_created(event)
      conversation.reload

      expect(conversation.labels.pluck(:name)).to contain_exactly('support', 'priority_customer')
    end

    it 'triggers automation on equal_to filter' do
      automation_rule.update!(
        conditions: [
          { 'values': ['sale'], 'attribute_key': 'content', 'query_operator': nil, 'filter_operator': 'equal_to' }
        ],
        actions: [
          { 'action_name' => 'add_label', 'action_params' => %w[sale_enquiry] }
        ]
      )

      event = Events::Base.new('message_created', Time.zone.now, { conversation: conversation, message: message_2 })
      listener.message_created(event)

      conversation.reload
      expect(conversation.labels.pluck(:name)).to contain_exactly('sale_enquiry')
    end
  end

  describe '#message_created' do
    before do
      automation_rule.update!(
        event_name: 'message_created',
        name: 'Call actions message created',
        description: 'Add labels, assign team after message created',
        conditions: [{ 'values': ['incoming'], 'attribute_key': 'message_type', 'query_operator': nil, 'filter_operator': 'equal_to' }]
      )
    end

    let!(:message) { create(:message, account: account, conversation: conversation, message_type: 'incoming') }
    let!(:event) do
      Events::Base.new('message_created', Time.zone.now, { conversation: conversation, message: message })
    end

    context 'when rule matches' do
      it 'triggers automation rule to assign team' do
        expect(conversation.team_id).not_to eq(team.id)
        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)
        listener.message_created(event)
        conversation.reload

        expect(conversation.team_id).to eq(team.id)
      end

      it 'triggers automation rule to add label' do
        expect(conversation.labels).to eq([])
        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)
        listener.message_created(event)
        conversation.reload

        expect(conversation.labels.pluck(:name)).to contain_exactly('support', 'priority_customer')
      end

      it 'triggers automation rule to assign best agent' do
        expect(conversation.assignee).to be_nil
        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)
        listener.message_created(event)
        conversation.reload

        expect(conversation.assignee).to eq(user_1)
      end

      it 'triggers automation rule send email transcript to the mentioned email' do
        mailer = double
        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)
        listener.message_created(event)
        conversation.reload

        allow(mailer).to receive(:conversation_transcript)
      end
    end
  end

  describe '#message_created with conversation and contacts based conditions' do
    before do
      automation_rule.update!(
        event_name: 'message_created',
        name: 'Call actions message created',
        description: 'Send Message in the conversation',
        conditions: [
          { attribute_key: 'team_id', filter_operator: 'equal_to', values: [team.id], query_operator: 'AND' }.with_indifferent_access,
          { attribute_key: 'message_type', filter_operator: 'equal_to', values: ['incoming'], query_operator: 'AND' }.with_indifferent_access,
          { attribute_key: 'email', filter_operator: 'contains', values: ['example.com'], query_operator: 'AND' }.with_indifferent_access,
          { attribute_key: 'company', filter_operator: 'equal_to', values: ['Marvel'], query_operator: nil }.with_indifferent_access
        ],
        actions: [
          { 'action_name' => 'send_message', 'action_params' => ['Send this message.'] },
          { 'action_name' => 'send_email_transcript', 'action_params' => ['new_agent@example.com'] }
        ]
      )
      conversation.update!(team_id: team.id)
      conversation.contact.update!(email: 'tj@example.com', additional_attributes: { 'company': 'Marvel' })
    end

    let!(:message) { create(:message, account: account, conversation: conversation, message_type: 'incoming') }
    let!(:event) do
      Events::Base.new('message_created', Time.zone.now, { conversation: conversation, message: message })
    end

    context 'when rule matches' do
      it 'triggers automation rule send email transcript to the mentioned email' do
        mailer = double
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:conversation_transcript)

        listener.message_created(event)
        conversation.reload

        expect(mailer).to have_received(:conversation_transcript).with(conversation, 'new_agent@example.com')
      end

      it 'triggers automation rule send message to the contacts' do
        expect(conversation.messages.count).to eq(1)
        listener.message_created(event)
        conversation.reload

        expect(conversation.messages.count).to eq(2)
        expect(conversation.messages.last.content).to eq('Send this message.')
      end
    end

    context 'when rule does not match' do
      before do
        conversation.update!(team_id: team.id)
        conversation.contact.update!(email: 'tj@ex.com', additional_attributes: { 'company': 'DC' })
      end

      let!(:message) { create(:message, account: account, conversation: conversation, message_type: 'outgoing') }
      let!(:event) do
        Events::Base.new('message_created', Time.zone.now, { conversation: conversation, message: message })
      end

      it 'triggers automation rule but wont send message' do
        expect(conversation.messages.count).to eq(1)
        listener.message_created(event)
        conversation.reload

        expect(conversation.messages.count).to eq(1)
        expect(conversation.messages.last.content).to eq('Incoming Message')
      end
    end
  end

  describe '#conversation_created with contacts based conditions' do
    before do
      automation_rule.update!(
        event_name: 'conversation_created',
        name: 'Call actions message created',
        description: 'Send Message in the conversation',
        conditions: [
          { attribute_key: 'team_id', filter_operator: 'equal_to', values: [team.id], query_operator: 'AND' }.with_indifferent_access,
          { attribute_key: 'email', filter_operator: 'contains', values: ['example.com'], query_operator: 'AND' }.with_indifferent_access,
          { attribute_key: 'company', filter_operator: 'equal_to', values: ['Marvel'], query_operator: nil }.with_indifferent_access
        ],
        actions: [
          { 'action_name' => 'send_message', 'action_params' => ['Send this message.'] },
          { 'action_name' => 'send_email_transcript', 'action_params' => ['new_agent@example.com'] }
        ]
      )
      conversation.update!(team_id: team.id)
      conversation.contact.update!(email: 'tj@example.com', additional_attributes: { 'company': 'Marvel' })
    end

    let!(:message) { create(:message, account: account, conversation: conversation, message_type: 'incoming') }
    let!(:event) do
      Events::Base.new('conversation_created', Time.zone.now, { conversation: conversation, message: message })
    end

    context 'when rule matches' do
      it 'triggers automation rule send email transcript to the mentioned email' do
        mailer = double
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:conversation_transcript)

        listener.conversation_created(event)

        conversation.reload

        expect(mailer).to have_received(:conversation_transcript).with(conversation, 'new_agent@example.com')
      end

      it 'triggers automation rule send message to the contacts' do
        expect(conversation.messages.count).to eq(1)

        listener.conversation_created(event)

        conversation.reload

        expect(conversation.messages.count).to eq(2)
        expect(conversation.messages.last.content).to eq('Send this message.')
        expect(conversation.messages.last.content_attributes[:automation_rule_id]).to eq(automation_rule.id)
      end
    end

    context 'when rule does not match' do
      before do
        conversation.update!(team_id: team.id)
        conversation.contact.update!(email: 'tj@ex.com', additional_attributes: { 'company': 'DC' })
      end

      let!(:message) { create(:message, account: account, conversation: conversation, message_type: 'outgoing') }
      let!(:event) do
        Events::Base.new('conversation_created', Time.zone.now, { conversation: conversation, message: message })
      end

      it 'triggers automation rule but wont send message' do
        expect(conversation.messages.count).to eq(1)

        listener.conversation_created(event)

        conversation.reload

        expect(conversation.messages.count).to eq(1)
        expect(conversation.messages.last.content).to eq('Incoming Message')
      end
    end
  end

  describe '#message_created for tweet events' do
    before do
      automation_rule.update!(
        event_name: 'message_created',
        name: 'Call actions message created',
        description: 'Send Message in the conversation',
        conditions: [
          { attribute_key: 'status', filter_operator: 'equal_to', values: ['open'], query_operator: nil }.with_indifferent_access
        ],
        actions: [
          { 'action_name' => 'send_message', 'action_params' => ['Send this message.'] },
          { 'action_name' => 'send_attachment', 'action_params' => [123] },
          { 'action_name' => 'send_email_transcript', 'action_params' => ['new_agent@example.com'] }
        ]
      )
    end

    context 'when rule matches' do
      let(:tweet) { create(:conversation, additional_attributes: { type: 'tweet' }, inbox: inbox, account: account) }
      let(:event) { Events::Base.new('message_created', Time.zone.now, { conversation: tweet, message: message }) }
      let!(:message) { create(:message, account: account, conversation: tweet, message_type: 'incoming') }

      it 'triggers automation rule except send_message and send_attachment' do
        mailer = double
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:conversation_transcript)

        listener.message_created(event)
        expect(mailer).to have_received(:conversation_transcript).with(tweet, 'new_agent@example.com')
      end

      it 'does not triggers automation rule send message or send attachment' do
        expect(tweet.messages.count).to eq(1)

        listener.message_created(event)

        tweet.reload

        expect(tweet.messages.count).to eq(1)
        expect(tweet.messages.last.content).to eq(message.content)
      end
    end
  end

  describe '#conversation_created for two accounts' do
    let!(:new_account) { create(:account) }

    before do
      new_inbox = create(:inbox, account: new_account)
      new_conversation = create(:conversation, inbox: new_inbox, account: new_account)
      new_automation_rule = create(:automation_rule, account: new_account, name: 'Test Automation Rule - 1')

      create(:message, account: account, conversation: conversation, message_type: 'incoming')
      create(:message, account: new_account, conversation: new_conversation, message_type: 'incoming')

      automation_rule.update!(
        event_name: 'conversation_created',
        conditions: [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['all'], query_operator: nil }.with_indifferent_access],
        actions: [{ 'action_name' => 'send_message', 'action_params' => ['Send this message.'] }]
      )
      new_automation_rule.update!(
        event_name: 'conversation_created',
        conditions: [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['all'], query_operator: nil }.with_indifferent_access],
        actions: [{ 'action_name' => 'send_message', 'action_params' => ['Send this message. - 1'] }]
      )
    end

    it 'triggers automation at the same time' do
      new_conversation = new_account.conversations.last
      new_automation_rule = new_account.automation_rules.last

      event = Events::Base.new('conversation_created', Time.zone.now, { conversation: conversation })
      new_event = Events::Base.new('conversation_created', Time.zone.now, { conversation: new_conversation })

      listener.conversation_created(event)
      listener.conversation_created(new_event)

      expect(conversation.messages.count).to eq(2)
      expect(new_conversation.messages.count).to eq(2)

      expect(conversation.messages.last.content).to eq('Send this message.')
      expect(new_conversation.messages.last.content).to eq('Send this message. - 1')

      expect(conversation.messages.last.content_attributes).to eq({ 'automation_rule_id' => automation_rule.id })
      expect(new_conversation.messages.last.content_attributes).to eq({ 'automation_rule_id' => new_automation_rule.id })
    end
  end
end
