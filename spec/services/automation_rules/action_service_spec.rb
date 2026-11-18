require 'rails_helper'

RSpec.describe AutomationRules::ActionService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let!(:rule) do
    create(:automation_rule, account: account,
                             actions: [
                               { action_name: 'send_webhook_event', action_params: ['https://example.com'] },
                               { action_name: 'send_message', action_params: { message: 'Hello' } }
                             ])
  end

  describe 'attachment authorization for stored actions' do
    before do
      rule.files.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
    end

    it 'only sends rule files when stored actions also reference another account attachment' do
      foreign_message = create(:message, :with_attachment)
      foreign_blob = foreign_message.attachments.first.file.blob
      own_blob = rule.files.first.blob
      rule.update!(actions: [{ action_name: 'send_attachment', action_params: [own_blob.id, foreign_blob.id] }])

      described_class.new(rule, account, conversation).perform

      expect(conversation.messages.last.attachments.map { |attachment| attachment.file.blob_id }).to eq([own_blob.id])
    end

    it 'does not send another account attachment when no requested blob belongs to the rule' do
      foreign_message = create(:message, :with_attachment)
      foreign_blob = foreign_message.attachments.first.file.blob
      rule.update!(actions: [{ action_name: 'send_attachment', action_params: [foreign_blob.id] }])

      expect { described_class.new(rule, account, conversation).perform }.not_to change(conversation.messages, :count)
    end

    it 'does not send files belonging to another rule in the same account' do
      other_rule = create(:automation_rule, account: account)
      other_rule.files.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      rule.update!(actions: [{ action_name: 'send_attachment', action_params: [other_rule.files.first.blob_id] }])

      expect { described_class.new(rule, account, conversation).perform }.not_to change(conversation.messages, :count)
    end
  end

  describe '#perform' do
    context 'when actions are defined in the rule' do
      it 'will call the actions' do
        expect(Messages::MessageBuilder).to receive(:new)
        expect(WebhookJob).to receive(:perform_later)
        described_class.new(rule, account, conversation).perform
      end
    end

    describe '#perform with send_attachment action' do
      let(:message_builder) { double }

      before do
        allow(Messages::MessageBuilder).to receive(:new).and_return(message_builder)
        rule.actions.delete_if { |a| a['action_name'] == 'send_message' }
        rule.files.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        rule.save!
        rule.actions << { action_name: 'send_attachment', action_params: [rule.files.first.blob_id] }
      end

      it 'will send attachment' do
        expect(message_builder).to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end

      it 'will not send attachment is conversation is a tweet' do
        twitter_inbox = create(:inbox, channel: create(:channel_twitter_profile, account: account))
        conversation = create(:conversation, inbox: twitter_inbox, additional_attributes: { type: 'tweet' })
        expect(message_builder).not_to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end
    end

    describe '#perform with send_webhook_event action' do
      it 'will send webhook event' do
        expect(rule.actions.pluck('action_name')).to include('send_webhook_event')
        expect(WebhookJob).to receive(:perform_later)
        described_class.new(rule, account, conversation).perform
      end
    end

    describe '#perform with send_message action' do
      let(:message_builder) { double }

      before do
        allow(Messages::MessageBuilder).to receive(:new).and_return(message_builder)
      end

      it 'will send message' do
        expect(rule.actions.pluck('action_name')).to include('send_message')
        expect(message_builder).to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end

      it 'will not send message if conversation is a tweet' do
        expect(rule.actions.pluck('action_name')).to include('send_message')
        twitter_inbox = create(:inbox, channel: create(:channel_twitter_profile, account: account))
        conversation = create(:conversation, inbox: twitter_inbox, additional_attributes: { type: 'tweet' })
        expect(message_builder).not_to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end
    end

    describe '#perform with send_email_to_team action' do
      let!(:team) { create(:team, account: account) }

      before do
        rule.actions << { action_name: 'send_email_to_team', action_params: [{ team_ids: [team.id], message: 'Hello' }] }
      end

      it 'will send email to team, parameterized with the account whose brand it wears' do
        # Spying on the real parameterized mailer rather than an instance_double: it answers
        # through method_missing, so a verifying double refuses the very method it responds to.
        mailer = TeamNotifications::AutomationNotificationMailer.with(account: account)
        allow(TeamNotifications::AutomationNotificationMailer).to receive(:with).with(account: account).and_return(mailer)
        expect(mailer).to receive(:conversation_creation).with(conversation, team, 'Hello').and_call_original

        described_class.new(rule, account, conversation).perform
      end

      # The mailer clears Current so it renders for one account only. It used to leave it
      # cleared, which cost every later action in the same rule its actor.
      it 'still runs the actions that follow as the rule' do
        rule.actions = [
          { action_name: 'send_email_to_team', action_params: [{ team_ids: [team.id], message: 'Hello' }] },
          { action_name: 'send_message', action_params: { message: 'Hello again' } }
        ]
        actor = nil
        allow(Messages::MessageBuilder).to receive(:new) do
          actor = Current.executed_by
          instance_double(Messages::MessageBuilder, perform: nil)
        end

        described_class.new(rule, account, conversation).perform

        expect(actor).to eq(rule)
      end
    end

    describe 'team ownership for stored email actions' do
      let(:foreign_team) { create(:team) }

      before do
        allow(account).to receive(:within_email_rate_limit?).and_return(true)
      end

      it 'does not email another account team from an existing rule' do
        rule.update!(actions: [{ action_name: 'send_email_to_team', action_params: [{ team_ids: [foreign_team.id], message: 'Hello' }] }])
        expect(TeamNotifications::AutomationNotificationMailer).not_to receive(:conversation_creation)
        expect(account).not_to receive(:increment_email_sent_count)

        described_class.new(rule.reload, account, conversation).perform
      end

      it 'only emails own teams when stored ids span accounts' do
        own_team = create(:team, account: account)
        rule.update!(actions: [{ action_name: 'send_email_to_team',
                                 action_params: [{ team_ids: [own_team.id, foreign_team.id], message: 'Hello' }] }])
        delivery = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
        expect(TeamNotifications::AutomationNotificationMailer).to receive(:conversation_creation)
          .with(conversation, own_team, 'Hello').once.and_return(delivery)
        expect(account).to receive(:increment_email_sent_count).once

        described_class.new(rule.reload, account, conversation).perform
      end

      it 'stops before emailing when the account limit is exhausted' do
        own_team = create(:team, account: account)
        rule.update!(actions: [{ action_name: 'send_email_to_team', action_params: [{ team_ids: [own_team.id], message: 'Hello' }] }])
        allow(account).to receive(:within_email_rate_limit?).and_return(false)
        expect(TeamNotifications::AutomationNotificationMailer).not_to receive(:conversation_creation)
        expect(account).not_to receive(:increment_email_sent_count)

        described_class.new(rule.reload, account, conversation).perform
      end
    end

    describe '#perform with remove assignment actions' do
      let!(:team) { create(:team, account: account) }

      before do
        conversation.update!(assignee: agent, team: team)
        rule.actions = [
          { action_name: 'remove_assigned_agent', action_params: [] },
          { action_name: 'remove_assigned_team', action_params: [] }
        ]
        rule.save!
      end

      it 'removes assignee and team from the conversation' do
        described_class.new(rule, account, conversation).perform

        expect(conversation.reload.assignee).to be_nil
        expect(conversation.team).to be_nil
      end
    end

    describe '#perform with remove_custom_attribute action' do
      before do
        conversation.update!(custom_attributes: { 'fechamento' => 'Em negociação', 'origem' => 'tráfego pago' })
        rule.actions = [{ action_name: 'remove_custom_attribute', action_params: ['fechamento'] }]
        rule.save!
      end

      # Writing an empty value instead would leave the key behind, and on a list attribute that reads
      # as unset on screen while hiding the control an agent would use to clear it.
      it 'drops the key instead of emptying it, and leaves the other attributes alone' do
        described_class.new(rule, account, conversation).perform

        expect(conversation.reload.custom_attributes).to eq({ 'origem' => 'tráfego pago' })
      end

      it 'does not touch the conversation when the attribute was never set' do
        rule.update!(actions: [{ action_name: 'remove_custom_attribute', action_params: ['inexistente'] }])

        expect { described_class.new(rule, account, conversation).perform }.not_to(change { conversation.reload.updated_at })
      end
    end

    describe '#perform with send_email_transcript action' do
      before do
        allow(account).to receive(:email_transcript_enabled?).and_return(true)
        allow(account).to receive(:within_email_rate_limit?).and_return(true)
        allow(account).to receive(:increment_email_sent_count).and_return(true)
        rule.actions << { action_name: 'send_email_transcript', action_params: ['contact@example.com, agent@example.com,agent1@example.com'] }
        rule.save!
      end

      it 'will send email to transcript to action params emails' do
        mailer = double
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:conversation_transcript).with(conversation, 'contact@example.com')
        allow(mailer).to receive(:conversation_transcript).with(conversation, 'agent@example.com')
        allow(mailer).to receive(:conversation_transcript).with(conversation, 'agent1@example.com')

        described_class.new(rule, account, conversation).perform
        expect(mailer).to have_received(:conversation_transcript).exactly(3).times
      end

      it 'will send email to transcript to contacts' do
        rule.actions = [{ action_name: 'send_email_transcript', action_params: ['{{contact.email}}'] }]
        rule.save!

        mailer = double
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:conversation_transcript).with(conversation, conversation.contact.email)

        described_class.new(rule.reload, account, conversation).perform
        expect(mailer).to have_received(:conversation_transcript).exactly(1).times
      end
    end

    describe '#perform with add_label action' do
      before do
        rule.actions << { action_name: 'add_label', action_params: %w[bug feature] }
        rule.save!
      end

      it 'will add labels to conversation' do
        described_class.new(rule, account, conversation).perform
        expect(conversation.reload.label_list).to include('bug', 'feature')
      end

      it 'will not duplicate existing labels' do
        conversation.add_labels(['bug'])
        described_class.new(rule, account, conversation).perform
        expect(conversation.reload.label_list.count('bug')).to eq(1)
        expect(conversation.reload.label_list).to include('feature')
      end
    end

    describe '#perform with remove_label action' do
      before do
        conversation.add_labels(%w[bug feature support])
        rule.actions << { action_name: 'remove_label', action_params: %w[bug feature] }
        rule.save!
      end

      it 'will remove specified labels from conversation' do
        described_class.new(rule, account, conversation).perform
        expect(conversation.reload.label_list).not_to include('bug', 'feature')
        expect(conversation.reload.label_list).to include('support')
      end

      it 'will not fail if labels do not exist on conversation' do
        conversation.update_labels(['support']) # Remove bug and feature first
        expect { described_class.new(rule, account, conversation).perform }.not_to raise_error
        expect(conversation.reload.label_list).to include('support')
      end
    end

    describe '#perform with add_private_note action' do
      let(:message_builder) { double }

      before do
        allow(Messages::MessageBuilder).to receive(:new).and_return(message_builder)
        rule.actions.delete_if { |a| a['action_name'] == 'send_message' }
        rule.actions << { action_name: 'add_private_note', action_params: ['Note'] }
      end

      it 'will add private note' do
        expect(message_builder).to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end

      it 'will not add note if conversation is a tweet' do
        twitter_inbox = create(:inbox, channel: create(:channel_twitter_profile, account: account))
        conversation = create(:conversation, inbox: twitter_inbox, additional_attributes: { type: 'tweet' })
        expect(message_builder).not_to receive(:perform)
        described_class.new(rule, account, conversation).perform
      end
    end

    describe '#perform with assign_agent action' do
      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
        rule.actions << { action_name: 'assign_agent', action_params: ['last_responding_agent'] }
      end

      it 'assigns the conversation to the last responding agent' do
        create(:message, message_type: :outgoing, account: account,
                         inbox: conversation.inbox, conversation: conversation, sender: agent)

        described_class.new(rule, account, conversation).perform

        expect(conversation.reload.assignee).to eq(agent)
      end
    end

    describe '#perform with create_scheduled_message action' do
      it 'creates scheduled message with attachment from rule files' do
        rule.files.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        rule.save!
        rule.actions = [{ action_name: 'create_scheduled_message',
                          action_params: [{ content: 'Scheduled', delay_minutes: 5, blob_id: rule.files.first.blob_id }] }]

        expect { described_class.new(rule, account, conversation).perform }
          .to change { conversation.scheduled_messages.count }.by(1)

        scheduled_message = conversation.scheduled_messages.last
        expect(scheduled_message.content).to eq('Scheduled')
        expect(scheduled_message.author).to eq(rule)
        expect(scheduled_message.attachment).to be_attached
      end
    end
  end

  # The actions render their activity messages as they commit, in the thread's locale. A rule runs in
  # Sidekiq, whose locale is the one of whoever enqueued the event (English for an inbound message)
  # or the process default, so the run names the account's.
  describe 'the language of the activity messages a run writes' do
    let(:conversation) { create(:conversation, account: account, assignee: agent, status: :open) }
    let(:rule) do
      create(:automation_rule, account: account, actions: [
               { action_name: 'add_label', action_params: ['representante'] },
               { action_name: 'change_priority', action_params: ['high'] },
               { action_name: 'assign_agent', action_params: ['nil'] },
               { action_name: 'resolve_conversation', action_params: [] }
             ])
    end

    def activity_contents
      ActiveJob::Base.queue_adapter.enqueued_jobs
                     .select { |job| job['job_class'] == 'Conversations::ActivityMessageJob' }
                     .map { |job| job['arguments'].second['content'] }
    end

    before { clear_enqueued_jobs }

    it 'writes them in the account locale when the thread arrives in another one' do
      account.update!(locale: 'pt_BR')

      I18n.with_locale(:en) { described_class.new(rule, account, conversation).perform }

      expect(activity_contents).to contain_exactly(
        'Sistema de Automação adicionou representante',
        'Sistema de Automação definiu a prioridade para high',
        'Conversa desatribuída por Sistema de Automação',
        'Conversa foi marcada como resolvida por Sistema de Automação'
      )
    end

    it 'writes them in English for an English account, even from a pt_BR thread' do
      account.update!(locale: 'en')

      I18n.with_locale(:pt_BR) { described_class.new(rule, account, conversation).perform }

      expect(activity_contents).to include('Conversation unassigned by Automation System',
                                           'Conversation was marked resolved by Automation System')
      expect(activity_contents.join).not_to include('Sistema de Automação')
    end

    it 'hands the thread back in the locale it came with' do
      account.update!(locale: 'pt_BR')

      locale_after = I18n.with_locale(:en) do
        described_class.new(rule, account, conversation).perform
        I18n.locale
      end

      expect(locale_after).to eq(:en)
    end
  end

  describe 'conversation variables in the text of an action' do
    let(:agent) { create(:user, account: account, name: 'john doe') }
    let(:conversation) do
      create(:conversation, account: account, assignee: agent, custom_attributes: { 'fechamento' => 'Em negociação' })
    end

    def notes_of(record)
      record.reload.messages.where(private: true).order(:id).pluck(:content)
    end

    it 'reads the state the run is about to destroy, and the live state after it did' do
      rule = create(:automation_rule, account: account, actions: [
                      { action_name: 'assign_agent', action_params: ['nil'] },
                      { action_name: 'remove_custom_attribute', action_params: ['fechamento'] },
                      { action_name: 'add_private_note',
                        action_params: ['Antes=[{{conversation.before.assignee.name}}|{{conversation.before.custom_attribute.fechamento}}] ' \
                                        'Agora=[{{conversation.assignee.name}}|{{conversation.custom_attribute.fechamento}}]'] }
                    ])

      described_class.new(rule, account, conversation).perform

      expect(notes_of(conversation)).to eq ['Antes=[John Doe|Em negociação] Agora=[|]']
    end

    it 'gives every note of the same run the state of the start of the run' do
      snapshot_text = '[{{conversation.before.assignee.name}}|{{conversation.before.custom_attribute.fechamento}}]'
      rule = create(:automation_rule, account: account, actions: [
                      { action_name: 'add_private_note', action_params: ["A=#{snapshot_text}"] },
                      { action_name: 'assign_agent', action_params: ['nil'] },
                      { action_name: 'remove_custom_attribute', action_params: ['fechamento'] },
                      { action_name: 'add_private_note', action_params: ["B=#{snapshot_text}"] }
                    ])

      described_class.new(rule, account, conversation).perform

      expect(notes_of(conversation)).to eq ['A=[John Doe|Em negociação]', 'B=[John Doe|Em negociação]']
    end

    it 'keeps a snapshot value literal when it carries liquid syntax of its own' do
      conversation.update!(custom_attributes: { 'fechamento' => 'Em negociação {{contact.name}}' })
      rule = create(:automation_rule, account: account, actions: [
                      { action_name: 'remove_custom_attribute', action_params: ['fechamento'] },
                      { action_name: 'add_private_note', action_params: ['Tab: {{conversation.before.custom_attribute.fechamento}}'] }
                    ])

      described_class.new(rule, account, conversation).perform

      expect(notes_of(conversation)).to eq ['Tab: Em negociação {{contact.name}}']
    end

    it 'leaves no snapshot behind for whatever runs next in the same thread' do
      rule = create(:automation_rule, account: account, actions: [{ action_name: 'assign_agent', action_params: ['nil'] }])

      described_class.new(rule, account, conversation).perform

      expect(Current.conversation_snapshot).to be_nil
    end

    it 'does not carry the snapshot of one conversation into the run of the next' do
      other = create(:conversation, account: account, inbox: conversation.inbox,
                                    custom_attributes: { 'fechamento' => 'Parou de responder' })
      note_text = 'Estava com: [{{conversation.before.assignee.name}}] ' \
                  'Tab: [{{conversation.before.custom_attribute.fechamento}}]'
      rule = create(:automation_rule, account: account, actions: [
                      { action_name: 'assign_agent', action_params: ['nil'] },
                      { action_name: 'add_private_note', action_params: [note_text] }
                    ])

      described_class.new(rule, account, conversation).perform
      described_class.new(rule, account, other).perform

      expect(notes_of(conversation)).to eq ['Estava com: [John Doe] Tab: [Em negociação]']
      expect(notes_of(other)).to eq ['Estava com: [] Tab: [Parou de responder]']
    end
  end
end
