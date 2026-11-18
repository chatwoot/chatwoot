# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/liquidable_shared.rb'

RSpec.describe Message do
  before do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:reindex_for_search).and_return(true)
    # rubocop:enable RSpec/AnyInstance
  end

  context 'with validations' do
    it { is_expected.to validate_presence_of(:inbox_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'length validations' do
    let!(:message) { create(:message) }

    context 'when it validates name length' do
      it 'valid when within limit' do
        message.content = 'a' * 120_000
        expect(message.valid?).to be true
      end

      it 'invalid when crossed the limit' do
        message.content = 'a' * 150_001
        message.processed_message_content = 'a' * 150_001
        message.valid?

        expect(message.errors[:processed_message_content]).to include('is too long (maximum is 150000 characters)')
        expect(message.errors[:content]).to include('is too long (maximum is 150000 characters)')
      end

      it 'adds error in case of message flooding' do
        with_modified_env 'CONVERSATION_MESSAGE_PER_MINUTE_LIMIT': '2' do
          conversation = message.conversation
          create(:message, conversation: conversation)
          conv_new_message = build(:message, conversation: message.conversation)

          expect(conv_new_message.valid?).to be false
          expect(conv_new_message.errors[:base]).to eq(['Too many messages'])
        end
      end

      context 'when skip_message_flooding_validation is set' do
        it 'skips message flooding validation when set to true' do
          with_modified_env 'CONVERSATION_MESSAGE_PER_MINUTE_LIMIT': '2' do
            conversation = message.conversation
            create(:message, conversation: conversation)
            conv_new_message = build(:message, conversation: message.conversation)

            expect(conv_new_message.valid?).to be false
            expect(conv_new_message.errors[:base]).to eq(['Too many messages'])

            conv_new_message.skip_message_flooding_validation = true
            conv_new_message.valid?
            expect(conv_new_message.errors[:base]).to be_empty
            expect(conv_new_message.valid?).to be true
          end
        end

        it 'still validates other attributes when message flooding is skipped' do
          message_without_required_fields = build(:message)
          message_without_required_fields.account_id = nil
          message_without_required_fields.inbox_id = nil
          message_without_required_fields.skip_message_flooding_validation = true

          expect(message_without_required_fields.valid?).to be false
          expect(message_without_required_fields.errors[:account_id]).to include("can't be blank")
          expect(message_without_required_fields.errors[:inbox_id]).to include("can't be blank")
        end

        it 'allows bulk message creation when skip_message_flooding_validation is true' do
          with_modified_env 'CONVERSATION_MESSAGE_PER_MINUTE_LIMIT': '2' do
            conversation = message.conversation

            messages_to_create = 5
            created_messages = []

            messages_to_create.times do |i|
              new_message = build(:message,
                                  conversation: conversation,
                                  content: "Bulk message #{i + 1}")
              new_message.skip_message_flooding_validation = true

              expect(new_message.valid?).to be true
              new_message.save!
              created_messages << new_message
            end

            expect(created_messages.count).to eq(messages_to_create)
            expect(conversation.messages.count).to eq(messages_to_create + 1)
          end
        end
      end
    end

    context 'when it validates source_id length' do
      it 'valid when source_id is within text limit (20000 chars)' do
        long_source_id = 'a' * 10_000
        message.source_id = long_source_id
        expect(message.valid?).to be true
      end

      it 'valid when source_id is exactly 20000 characters' do
        long_source_id = 'a' * 20_000
        message.source_id = long_source_id
        expect(message.valid?).to be true
      end

      it 'invalid when source_id exceeds text limit (20000 chars)' do
        long_source_id = 'a' * 20_001
        message.source_id = long_source_id
        message.valid?

        expect(message.errors[:source_id]).to include('is too long (maximum is 20000 characters)')
      end

      it 'handles long email Message-ID headers correctly' do
        # Simulate a long Message-ID like some email systems generate
        long_message_id = "msg-#{SecureRandom.hex(240)}@verylongdomainname.example.com"[0...500]
        message.source_id = long_message_id
        message.content_type = 'incoming_email'

        expect(message.valid?).to be true
        expect(message.source_id.length).to eq(500)
      end

      it 'allows nil source_id' do
        message.source_id = nil
        expect(message.valid?).to be true
      end

      it 'allows empty string source_id' do
        message.source_id = ''
        expect(message.valid?).to be true
      end
    end
  end

  describe 'concerns' do
    it_behaves_like 'liqudable'
  end

  describe 'message_filter_helpers' do
    context 'when webhook_sendable?' do
      [
        { type: :incoming, expected: true },
        { type: :outgoing, expected: true },
        { type: :template, expected: true },
        { type: :activity, expected: false }
      ].each do |scenario|
        it "returns #{scenario[:expected]} for #{scenario[:type]} message" do
          message = create(:message, message_type: scenario[:type])
          expect(message.webhook_sendable?).to eq(scenario[:expected])
        end
      end
    end
  end

  describe '#push_event_data' do
    subject(:push_event_data) { message.push_event_data }

    let(:message) { create(:message, echo_id: 'random-echo_id') }

    let(:expected_data) do
      {

        account_id: message.account_id,
        additional_attributes: message.additional_attributes,
        content_attributes: message.content_attributes,
        content_type: message.content_type,
        content: message.content,
        conversation_id: message.conversation.display_id,
        created_at: message.created_at.to_i,
        external_source_ids: message.external_source_ids,
        id: message.id,
        inbox_id: message.inbox_id,
        message_type: message.message_type_before_type_cast,
        private: message.private,
        processed_message_content: message.processed_message_content,
        sender_id: message.sender_id,
        sender_type: message.sender_type,
        source_id: message.source_id,
        status: message.status,
        updated_at: message.updated_at,
        conversation: {
          assignee_id: message.conversation.assignee_id,
          contact_inbox: {
            source_id: message.conversation.contact_inbox.source_id
          },
          last_activity_at: message.conversation.last_activity_at.to_i,
          unread_count: message.conversation.unread_incoming_messages.count
        },
        sentiment: {},
        sender: message.sender.push_event_data,
        echo_id: 'random-echo_id'
      }
    end

    it 'returns push event payload' do
      expect(push_event_data).to eq(expected_data)
    end
  end

  describe '#widget_sender_data' do
    it 'returns only the type for a contact sender' do
      message = create(:message, message_type: :incoming, sender: create(:contact, email: 'jane@example.com'))

      expect(message.widget_sender_data).to eq(type: 'contact')
    end

    it 'returns the full event data for an agent sender' do
      message = create(:message, sender: create(:user))

      expect(message.widget_sender_data).to eq(message.sender.push_event_data)
    end
  end

  describe '#widget_push_event_data' do
    it 'keeps the message event and reduces a contact sender to its type' do
      message = create(:message, message_type: :incoming, sender: create(:contact, email: 'jane@example.com'))

      expect(message.widget_push_event_data).to eq(message.push_event_data.merge(sender: { type: 'contact' }))
    end

    it 'keeps an agent sender' do
      message = create(:message, sender: create(:user))

      expect(message.widget_push_event_data).to eq(message.push_event_data)
    end

    it 'keeps an agent bot sender with the inbox avatar fallback' do
      message = create(:message, sender: create(:agent_bot))

      expect(message.widget_push_event_data[:sender]).to eq(message.sender.push_event_data(message.inbox))
    end
  end

  describe 'message create event' do
    let!(:conversation) { create(:conversation) }

    before do
      conversation.reload
    end

    it 'updates the conversation first reply created at if it is the first outgoing message' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      outgoing_message = create(:message, message_type: :outgoing, conversation: conversation)

      expect(conversation.first_reply_created_at).to eq outgoing_message.created_at
      expect(conversation.waiting_since).to be_nil
    end

    it 'does not count a forwarded email as a reply to the contact' do
      create(:message, message_type: :outgoing, conversation: conversation, content_attributes: { forwarded_message_id: 1 })

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at
    end

    it 'records the first reply to the contact after a forwarded email' do
      create(:message, message_type: :outgoing, conversation: conversation, content_attributes: { forwarded_message_id: 1 })
      reply = create(:message, message_type: :outgoing, conversation: conversation)

      expect(conversation.first_reply_created_at).to eq reply.created_at
    end

    it 'does not update the conversation first reply created at if the message is incoming' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :incoming, conversation: conversation)

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at
    end

    it 'does not update the conversation first reply created at if the message is template' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :template, conversation: conversation)

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at
    end

    it 'does not update the conversation first reply created at if the message is activity' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :activity, conversation: conversation)

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at
    end

    it 'does not update the conversation first reply created at if the message is a private message' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :outgoing, conversation: conversation, private: true)

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      next_message = create(:message, message_type: :outgoing, conversation: conversation)
      expect(conversation.first_reply_created_at).to eq next_message.created_at
      expect(conversation.waiting_since).to be_nil
    end

    it 'does not update first reply if the message is sent as campaign' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :outgoing, conversation: conversation, additional_attributes: { campaign_id: 1 })

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at
    end

    it 'does not update first reply if the message is sent by automation' do
      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at

      create(:message, message_type: :outgoing, conversation: conversation, content_attributes: { automation_rule_id: 1 })

      expect(conversation.first_reply_created_at).to be_nil
      expect(conversation.waiting_since).to eq conversation.created_at
    end
  end

  describe '#reopen_conversation' do
    let(:conversation) { create(:conversation) }
    let(:message) { build(:message, message_type: :incoming, conversation: conversation) }

    it 'reopens resolved conversation when the message is from a contact' do
      conversation.update!(status: :resolved, ai_assignee: create(:agent_bot, account: conversation.account))
      message.save!
      expect(conversation.reload).to have_attributes(status: 'open', ai_assignee_type: nil, assignee_agent_bot_id: nil)
    end

    it 'reopens snoozed conversation when the message is from a contact' do
      conversation.update!(status: :snoozed, ai_assignee: create(:agent_bot, account: conversation.account))
      message.save!
      expect(conversation.reload).to have_attributes(status: 'open', ai_assignee_type: nil, assignee_agent_bot_id: nil)
    end

    it 'will not reopen if the conversation is muted' do
      conversation.resolved!
      conversation.mute!
      message.save!
      expect(message.conversation.open?).to be false
    end

    it 'will mark the conversation as pending if the agent bot is active' do
      agent_bot = create(:agent_bot, account: conversation.account)
      inbox = conversation.inbox
      inbox.agent_bot = agent_bot
      inbox.save!
      conversation.update!(status: :resolved, ai_assignee: agent_bot)
      message.save!
      expect(conversation.open?).to be false
      expect(conversation.pending?).to be true
      expect(conversation.reload.ai_assignee).to eq(agent_bot)
    end
  end

  describe 'handing a reopened conversation to the inbox agent bot' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
    let(:agent_bot) { create(:agent_bot, account: account) }
    let!(:agent_bot_inbox) { create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot) }
    let(:person) { create(:user, account: account, role: :agent) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: person) }
    let(:message) { build(:message, message_type: :incoming, conversation: conversation, account: account, inbox: inbox) }

    it 'makes the bot the owner of a conversation a person resolved, when the customer writes again' do
      conversation.resolved!
      message.save!

      conversation.reload
      expect(conversation).to be_pending
      expect(conversation.assignee).to be_nil
      expect(conversation.ai_assignee).to eq(agent_bot)
      expect(conversation.assignee_type).to eq('AgentBot')
    end

    it 'explains the handoff in a single activity line, in the account locale' do
      account.update!(locale: 'pt_BR')
      person.update!(name: 'Ana')
      agent_bot.update!(name: 'Atendente')
      conversation.resolved!

      expect { message.save! }
        .to have_enqueued_job(Conversations::ActivityMessageJob)
        .with(conversation, hash_including(content: 'Conversa passada de Ana para Atendente porque o cliente escreveu de novo')).exactly(:once)
    end

    it 'makes the bot the owner of a conversation resolved with no one assigned' do
      conversation.update!(assignee: nil)
      conversation.resolved!
      message.save!

      expect(conversation.reload.ai_assignee).to eq(agent_bot)
    end

    it 'leaves a conversation delegated to a specialist bot with that bot' do
      specialist = create(:agent_bot, account: account)
      conversation.update!(assignee: nil, ai_assignee: specialist)
      conversation.resolved!
      message.save!

      expect(conversation.reload).to be_pending
      expect(conversation.ai_assignee).to eq(specialist)
    end

    it 'leaves the person in place when the inbox bot is inactive' do
      agent_bot_inbox.update!(status: :inactive)
      conversation.resolved!
      message.save!

      expect(conversation.reload).to be_open
      expect(conversation.assignee).to eq(person)
    end

    # Dialogflow keeps the inbox's bot active on its own, so the reopen goes pending with the
    # agent bot switched off: the person stays, and Dialogflow answers.
    it 'does not hand the conversation to an inactive agent bot when Dialogflow keeps the inbox pending' do
      agent_bot_inbox.update!(status: :inactive)
      create(:integrations_hook, :dialogflow, inbox: inbox, account: account)
      conversation.resolved!
      message.save!

      expect(conversation.reload).to be_pending
      expect(conversation.assignee).to eq(person)
      expect(conversation.ai_assignee).to be_nil
    end

    # An API inbox can create the customer's message with an agent's token; the handoff is not that agent taking over.
    it 'hands the conversation to the bot when the inbox prevents takeover and another agent created the message' do
      inbox.update!(prevent_assignment_takeover: true)
      conversation.resolved!
      Current.user = create(:user, account: account, role: :agent)

      # Nor is the activity signed by that agent: the reason is the only assignment line.
      expect { message.save! }
        .to have_enqueued_job(Conversations::ActivityMessageJob)
        .with(conversation, hash_including(content: a_string_matching(/because the customer wrote again/))).exactly(:once)
      activity_lines = ActiveJob::Base.queue_adapter.enqueued_jobs
                                      .select { |job| job['job_class'] == 'Conversations::ActivityMessageJob' }
                                      .map { |job| job['arguments'].last['content'] }
      expect(activity_lines.grep(/assigned/i)).to be_empty
      expect(conversation.reload).to be_pending
      expect(conversation.ai_assignee).to eq(agent_bot)
    ensure
      Current.reset
    end

    it 'leaves a snoozed conversation with its person' do
      conversation.snoozed!
      message.save!

      expect(conversation.reload).to be_open
      expect(conversation.assignee).to eq(person)
    end

    context 'when something changes the conversation while the reopen is in flight' do
      it 'keeps a person an agent assigned in the meantime' do
        other = create(:user, account: account, role: :agent)
        conversation.resolved!
        Conversation.find(conversation.id).update!(assignee: other)

        message.save!

        expect(conversation.reload.assignee).to eq(other)
        expect(conversation.ai_assignee).to be_nil
      end

      it 'announces the bot when a second customer message reopens a copy read before the first' do
        conversation.resolved!
        stale_copy = Conversation.find(conversation.id)
        second = build(:message, message_type: :incoming, conversation: stale_copy, account: account, inbox: inbox)

        message.save!
        allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original
        second.save!

        expect(stale_copy.assignee_type).to eq('AgentBot')
        expect(stale_copy.assignee_id).to be_nil
        # The first message already made it pending: the second announces no status change of its own.
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::CONVERSATION_STATUS_CHANGED, any_args)
        expect(conversation.reload.ai_assignee).to eq(agent_bot)
      end

      it 'keeps the person and the open status when an agent reopened the conversation in the meantime' do
        conversation.resolved!
        Conversation.find(conversation.id).open!

        message.save!

        expect(conversation.reload).to be_open
        expect(conversation.assignee).to eq(person)
        expect(conversation.ai_assignee).to be_nil
      end
    end
  end

  describe 'keeping a reopened conversation with the person (reopen_owner)' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
    let(:agent_bot) { create(:agent_bot, account: account) }
    let(:person) { create(:user, account: account, role: :agent) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: person) }
    let(:message) { build(:message, message_type: :incoming, conversation: conversation, account: account, inbox: inbox) }

    before { create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot) }

    it 'opens the conversation with the person, and hands nothing to the bot' do
      inbox.update!(reopen_owner: :assignee)
      conversation.resolved!

      expect { message.save! }
        .not_to have_enqueued_job(Conversations::ActivityMessageJob).with(conversation, hash_including(content: a_string_matching(/wrote again/)))
      conversation.reload
      expect(conversation).to be_open
      expect(conversation.assignee).to eq(person)
      expect(conversation.ai_assignee).to be_nil
    end

    it 'hands a conversation resolved with no one assigned to the bot' do
      inbox.update!(reopen_owner: :assignee)
      conversation.update!(assignee: nil)
      conversation.resolved!
      message.save!

      expect(conversation.reload).to be_pending
      expect(conversation.ai_assignee).to eq(agent_bot)
    end

    it 'hands it to the bot when the team setting dropped the person in the same reopen' do
      team = create(:team, account: account)
      inbox.update!(reopen_owner: :assignee, drop_assignee_outside_team_on_reopen: true)
      conversation.update!(team: team)
      conversation.resolved!
      message.save!

      expect(conversation.reload).to be_pending
      expect(conversation.assignee).to be_nil
      expect(conversation.ai_assignee).to eq(agent_bot)
    end

    it 'keeps it open with the person when a second customer message reopens a copy read before the first' do
      inbox.update!(reopen_owner: :assignee)
      conversation.resolved!
      stale_copy = Conversation.find(conversation.id)
      second = build(:message, message_type: :incoming, conversation: stale_copy, account: account, inbox: inbox)

      message.save!
      second.save!

      expect(conversation.reload).to be_open
      expect(conversation.assignee).to eq(person)
      expect(conversation.ai_assignee).to be_nil
    end

    context 'with a window of hours' do
      before { inbox.update!(reopen_owner: :assignee_within_window, reopen_owner_window_hours: 2) }

      it 'keeps the person when the customer writes inside the window' do
        travel_to(1.hour.ago) { conversation.resolved! }
        message.save!

        expect(conversation.reload).to be_open
        expect(conversation.assignee).to eq(person)
      end

      it 'hands it to the bot when the customer writes after the window' do
        travel_to(3.hours.ago) { conversation.resolved! }
        message.save!

        expect(conversation.reload).to be_pending
        expect(conversation.ai_assignee).to eq(agent_bot)
      end

      it 'counts from the latest resolve' do
        travel_to(5.hours.ago) { conversation.resolved! }
        travel_to(4.hours.ago) { conversation.open! }
        travel_to(30.minutes.ago) { conversation.resolved! }
        message.save!

        expect(conversation.reload).to be_open
        expect(conversation.assignee).to eq(person)
      end

      it 'hands it to the bot when the resolve time was never recorded' do
        conversation.resolved!
        conversation.update_column(:status_changed_at, nil) # rubocop:disable Rails/SkipsModelValidations
        message.save!

        expect(conversation.reload.ai_assignee).to eq(agent_bot)
      end
    end
  end

  describe 'dropping an assignee outside the conversation team on reopen' do
    let(:account) { create(:account) }
    let(:team) { create(:team, account: account, name: 'plantão') }
    let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false, drop_assignee_outside_team_on_reopen: true) }
    let(:member) { create(:user, account: account, role: :agent, name: 'Ana') }
    let(:outsider) { create(:user, account: account, role: :agent, name: 'Bia') }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: outsider, team: team) }
    let(:message) { build(:message, message_type: :incoming, conversation: conversation, account: account, inbox: inbox) }
    let(:reason) { "Conversation unassigned from Bia because they are not a member of the conversation's team plantão" }
    let(:unassignment_activity) { hash_including(content: a_string_matching(/unassigned/i)) }

    # The outsider took the conversation while in the team and left it afterwards (a vacation, say):
    # assigning a non-member to a conversation of the team is refused on its own.
    before do
      team.add_members([member.id, outsider.id])
      conversation.update!(label_list: ['vip'])
      team.remove_members([outsider.id])
    end

    after { Current.reset }

    it 'drops the assignee when a customer reopens a resolved conversation, keeping team and labels' do
      conversation.resolved!
      message.save!

      conversation.reload
      expect(conversation).to be_open
      expect(conversation.assignee).to be_nil
      expect(conversation.team).to eq(team)
      expect(conversation.label_list).to eq(['vip'])
    end

    it 'drops the assignee when a customer reopens a snoozed conversation' do
      conversation.snoozed!
      message.save!

      expect(conversation.reload).to be_open
      expect(conversation.assignee).to be_nil
    end

    it 'drops the assignee when an active agent bot takes the reopened conversation as pending' do
      inbox.update!(agent_bot: create(:agent_bot))
      conversation.resolved!
      message.save!

      expect(conversation.reload).to be_pending
      expect(conversation.assignee).to be_nil
    end

    # The bot's own handoff line would name nobody, and the bot-assignment line would credit the agent
    # whose token posted the customer's message.
    it 'explains the team unassignment, and nothing else, when the inbox bot takes the reopened conversation' do
      inbox.update!(agent_bot: create(:agent_bot))
      conversation.resolved!
      Current.user = member

      expect { message.save! }
        .to have_enqueued_job(Conversations::ActivityMessageJob).with(conversation, hash_including(content: reason)).exactly(:once)
      activity_lines = ActiveJob::Base.queue_adapter.enqueued_jobs
                                      .select { |job| job['job_class'] == 'Conversations::ActivityMessageJob' }
                                      .map { |job| job['arguments'].last['content'] }
      expect(activity_lines.grep(/assigned to|handed from/i)).to be_empty
      expect(conversation.reload.ai_assignee).to be_present
    end

    it 'explains the unassignment in a single activity message' do
      conversation.resolved!

      expect { message.save! }
        .to have_enqueued_job(Conversations::ActivityMessageJob).with(conversation, hash_including(content: reason)).exactly(:once)
        .and have_enqueued_job(Conversations::ActivityMessageJob).with(conversation, unassignment_activity).exactly(:once)
    end

    it 'writes the activity message in the account locale' do
      account.update!(locale: 'pt_BR')
      conversation.resolved!

      expect { message.save! }.to have_enqueued_job(Conversations::ActivityMessageJob)
        .with(conversation, hash_including(content: 'Conversa desatribuída de Bia porque não é membro do time da conversa, plantão'))
    end

    it 'keeps an assignee who is a member of the team' do
      conversation.update!(assignee: member)
      conversation.resolved!
      message.save!

      expect(conversation.reload.assignee).to eq(member)
    end

    it 'keeps the assignee when the inbox setting is off' do
      inbox.update!(drop_assignee_outside_team_on_reopen: false)
      conversation.resolved!
      message.save!

      expect(conversation.reload).to be_open
      expect(conversation.assignee).to eq(outsider)
    end

    it 'leaves a conversation without a team untouched' do
      conversation.update!(team: nil)
      conversation.resolved!
      message.save!

      expect(conversation.reload.assignee).to eq(outsider)
    end

    it 'leaves a conversation without assignee untouched' do
      conversation.update!(assignee: nil)
      conversation.resolved!

      expect { message.save! }.not_to have_enqueued_job(Conversations::ActivityMessageJob).with(conversation, unassignment_activity)
      expect(conversation.reload.assignee).to be_nil
    end

    it 'leaves a conversation assigned to an agent bot untouched' do
      agent_bot = create(:agent_bot)
      inbox.update!(agent_bot: agent_bot)
      Conversations::AssignmentService.new(conversation: conversation, assignee_id: agent_bot.id, assignee_type: 'AgentBot').perform
      conversation.resolved!
      message.save!

      expect(conversation.reload.ai_assignee).to eq(agent_bot)
    end

    it 'does not touch the assignee of a conversation that is already open' do
      message.save!

      expect(conversation.reload.assignee).to eq(outsider)
    end

    it 'ignores outgoing messages on a resolved conversation' do
      conversation.resolved!
      create(:message, message_type: :outgoing, conversation: conversation, account: account, inbox: inbox, sender: member)

      expect(conversation.reload.assignee).to eq(outsider)
    end

    it 'does not override an agent reopening the conversation by hand' do
      conversation.resolved!
      Current.user = member
      conversation.open!

      expect(conversation.reload.assignee).to eq(outsider)
    end

    # An API inbox can create the customer's message with an agent's token; the rule is not that agent taking over.
    it 'drops the assignee even when the inbox prevents takeover and an agent created the message' do
      inbox.update!(prevent_assignment_takeover: true)
      conversation.resolved!
      Current.user = member

      # Nor is the activity signed by that agent: the reason is the only line.
      expect { message.save! }
        .to have_enqueued_job(Conversations::ActivityMessageJob).with(conversation, unassignment_activity).exactly(:once)
      expect(conversation.reload.assignee).to be_nil
    end

    context 'when something changes the conversation while the reopen is in flight' do
      it 'keeps the assignee an agent set in the meantime' do
        conversation.resolved!
        Conversation.find(conversation.id).update!(assignee: member)

        message.save!

        expect(conversation.reload).to be_open
        expect(conversation.assignee).to eq(member)
      end

      it 'keeps the assignee when an agent reopened the conversation in the meantime' do
        conversation.resolved!
        Conversation.find(conversation.id).open!

        message.save!

        expect(conversation.reload.assignee).to eq(outsider)
      end

      it 'judges the team the conversation has at that moment, not the one the message read' do
        other_team = create(:team, account: account)
        other_team.add_members([outsider.id])
        conversation.resolved!
        Conversation.find(conversation.id).update!(team: other_team)

        message.save!

        expect(conversation.reload.assignee).to eq(outsider)
        expect(conversation.team).to eq(other_team)
      end

      it 'drops the assignee once when two customer messages reopen it at the same time' do
        conversation.resolved!
        stale_copy = Conversation.find(conversation.id)
        second = build(:message, message_type: :incoming, conversation: stale_copy, account: account, inbox: inbox)

        expect do
          message.save!
          second.save!
        end.to have_enqueued_job(Conversations::ActivityMessageJob).with(conversation, unassignment_activity).exactly(:once)
        expect(conversation.reload).to be_open
        expect(conversation.assignee).to be_nil
      end
    end

    context 'with legacy auto-assignment' do
      before do
        inbox.update!(enable_auto_assignment: true)
        inbox.add_members([member.id, outsider.id])
      end

      it 'does not hand the conversation back to the dropped agent when they are the only one online' do
        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ outsider.id.to_s => 'online' })
        conversation.resolved!
        message.save!

        expect(conversation.reload.assignee).to be_nil
      end

      # The reason line still goes out when the same save hands the conversation to someone else.
      it 'hands it to an online member of the team, keeping the reason line' do
        allow(OnlineStatusTracker).to receive(:get_available_users)
          .and_return({ outsider.id.to_s => 'online', member.id.to_s => 'online' })
        conversation.resolved!

        expect { message.save! }
          .to have_enqueued_job(Conversations::ActivityMessageJob).with(conversation, hash_including(content: reason)).exactly(:once)
        expect(conversation.reload.assignee).to eq(member)
      end

      # The pick has to draw from the team the assignee was judged against: here the message read a team
      # the outsider is still in, while the row had already moved to one they are not.
      it 'picks from the team the row holds, not from the one the message read' do
        other_team = create(:team, account: account)
        other_team.add_members([outsider.id])
        conversation.update!(team: other_team)
        conversation.resolved!
        # Moved without the team-change callback, which would drop the outsider by itself.
        Conversation.where(id: conversation.id).update_all(team_id: team.id) # rubocop:disable Rails/SkipsModelValidations
        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ outsider.id.to_s => 'online' })

        message.save!

        expect(conversation.reload.assignee).to be_nil
        expect(conversation.team).to eq(team)
      end
    end

    context 'with assignment v2' do
      let(:service) { AutoAssignment::AssignmentService.new(inbox: inbox) }

      before do
        account.enable_features('assignment_v2')
        account.save!
        inbox.update!(enable_auto_assignment: true)
        inbox.add_members([member.id, outsider.id])
      end

      it 'does not hand the conversation back to the dropped agent when they are the only one online' do
        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ outsider.id.to_s => 'online' })
        conversation.resolved!
        message.save!
        service.perform_bulk_assignment

        expect(conversation.reload.assignee).to be_nil
      end

      it 'hands it to an online member of the team' do
        allow(OnlineStatusTracker).to receive(:get_available_users)
          .and_return({ outsider.id.to_s => 'online', member.id.to_s => 'online' })
        conversation.resolved!
        message.save!
        service.perform_bulk_assignment

        expect(conversation.reload.assignee).to eq(member)
      end

      # The bulk run loads its batch first and claims each row later: an agent picked from the
      # team in the snapshot must not claim a row that moved to a team they are not in.
      it 'does not claim with an agent picked from a team the row no longer has' do
        other_team = create(:team, account: account)
        other_team.add_members([outsider.id])
        conversation.update!(assignee: nil, team: other_team)
        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ outsider.id.to_s => 'online' })
        allow(service).to receive(:find_available_agent).and_wrap_original do |original, snapshot|
          agent = original.call(snapshot)
          Conversation.where(id: snapshot.id).update_all(team_id: team.id) # rubocop:disable Rails/SkipsModelValidations
          agent
        end

        service.perform_bulk_assignment

        expect(conversation.reload.assignee).to be_nil
      end
    end
  end

  describe '#mark_pending_conversation_as_open_for_human_response' do
    let(:conversation) { create(:conversation, status: :pending) }

    it 'does not mark the conversation open when pending is used without captain' do
      create(:message, message_type: :outgoing, conversation: conversation)
      expect(conversation.reload.pending?).to be true
    end
  end

  describe '#waiting since' do
    let(:conversation) { create(:conversation) }
    let(:agent) { create(:user, account: conversation.account) }
    let(:message) { build(:message, conversation: conversation) }

    it 'resets the waiting_since if an agent sent a reply' do
      message.message_type = :outgoing
      message.sender = agent
      message.save!

      expect(conversation.waiting_since).to be_nil
    end

    it 'sets the waiting_since if there is an incoming message' do
      conversation.update!(waiting_since: nil)
      message.message_type = :incoming
      message.save!

      expect(conversation.waiting_since).not_to be_nil
    end

    it 'does not overwrite the previous value if there are newer messages' do
      old_waiting_since = conversation.waiting_since
      message.message_type = :incoming
      message.save!
      conversation.reload

      expect(conversation.waiting_since).to eq old_waiting_since
    end

    context 'when bot has responded to the conversation' do
      let(:agent_bot) { create(:agent_bot, account: conversation.account) }

      before do
        # Create initial customer message
        create(:message, conversation: conversation, message_type: :incoming,
                         created_at: 2.hours.ago)
        conversation.update!(waiting_since: 2.hours.ago)

        # Bot responds
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: agent_bot, created_at: 1.hour.ago)
      end

      it 'resets waiting_since when customer sends a new message after bot response' do
        new_message = build(:message, conversation: conversation, message_type: :incoming)
        new_message.save!

        conversation.reload
        expect(conversation.waiting_since).to be_within(1.second).of(new_message.created_at)
      end

      it 'does not reset waiting_since if last response was from human agent' do
        # Human agent responds (clears waiting_since)
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: agent)
        conversation.reload
        expect(conversation.waiting_since).to be_nil

        # Customer sends new message
        new_message = build(:message, conversation: conversation, message_type: :incoming)
        new_message.save!

        conversation.reload
        expect(conversation.waiting_since).to be_within(1.second).of(new_message.created_at)
      end

      it 'clears waiting_since when bot responds' do
        # After the bot response in before block, waiting_since should already be cleared
        conversation.reload
        expect(conversation.waiting_since).to be_nil

        # Customer sends another message
        create(:message, conversation: conversation, message_type: :incoming,
                         created_at: 30.minutes.ago)
        conversation.reload
        expect(conversation.waiting_since).to be_within(1.second).of(30.minutes.ago)

        # Another bot response should clear it again
        create(:message, conversation: conversation, message_type: :outgoing,
                         sender: agent_bot, created_at: 15.minutes.ago)

        conversation.reload
        expect(conversation.waiting_since).to be_nil
      end
    end

    context 'when bot response should preserve waiting_since' do
      let(:agent_bot) { create(:agent_bot, account: conversation.account) }

      it 'does not clear waiting_since when preserve_waiting_since is set' do
        original_waiting_since = 45.minutes.ago
        conversation.update!(waiting_since: original_waiting_since)

        create(
          :message,
          conversation: conversation,
          message_type: :outgoing,
          sender: agent_bot,
          preserve_waiting_since: true
        )

        expect(conversation.reload.waiting_since).to be_within(1.second).of(original_waiting_since)
      end
    end
  end

  context 'with webhook_data' do
    it 'contains the message attachment when attachment is present' do
      message = create(:message)
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      attachment.save!
      expect(message.webhook_data.key?(:attachments)).to be true
    end

    it 'does not contain the message attachment when attachment is not present' do
      message = create(:message)
      expect(message.webhook_data.key?(:attachments)).to be false
    end

    # The bot payload's consumer orders the contact and the inbox it mirrors by these clocks, which no
    # conversation timestamp can stand in for: a contact edit moves neither conversation clock.
    it 'carries the contact and inbox clocks in meta.sender, sender and inbox' do
      message = create(:message, message_type: :incoming)
      contact = message.conversation.contact
      message.update!(sender: contact)
      contact.update!(custom_attributes: { 'plano' => 'prata' })

      payload = message.reload.webhook_data

      expect(payload[:conversation][:meta][:sender][:updated_at]).to eq(contact.reload.updated_at.to_f)
      expect(payload[:sender][:updated_at]).to eq(contact.updated_at.to_f)
      expect(payload[:inbox][:updated_at]).to eq(message.inbox.updated_at.to_f)
    end

    it 'uses raw content without markdown rendering for webhook content' do
      message = create(:message, content: 'Test **bold** content')

      webhook_data = message.webhook_data
      expect(webhook_data[:content]).to eq('Test **bold** content')
    end

    it 'includes CSAT survey link in webhook content for input_csat messages' do
      inbox = create(:inbox, channel: create(:channel_api))
      conversation = create(:conversation, inbox: inbox)
      message = create(:message, conversation: conversation, content_type: 'input_csat', content: 'Rate your experience')

      expect(message.webhook_data[:content]).to include('survey/responses/')
    end
  end

  context 'when message is created' do
    let(:message) { build(:message, account: create(:account)) }

    it 'updates conversation last_activity_at when created' do
      message.save!
      expect(message.created_at).to eq message.conversation.last_activity_at
    end

    it 'updates contact last_activity_at when created' do
      expect { message.save! }.to(change { message.sender.last_activity_at })
    end

    it 'triggers ::MessageTemplates::HookExecutionService' do
      hook_execution_service = double
      allow(MessageTemplates::HookExecutionService).to receive(:new).and_return(hook_execution_service)
      allow(hook_execution_service).to receive(:perform).and_return(true)

      message.save!

      expect(MessageTemplates::HookExecutionService).to have_received(:new).with(message: message)
      expect(hook_execution_service).to have_received(:perform)
    end

    context 'with conversation continuity' do
      let(:inbox_with_continuity) do
        create(:inbox, account: message.account,
                       channel: build(:channel_widget, account: message.account, continuity_via_email: true))
      end

      it 'schedules email notification for outgoing messages in website channel' do
        message.inbox = inbox_with_continuity
        message.conversation.update!(inbox: inbox_with_continuity)
        message.conversation.contact.update!(email: 'test@example.com')
        message.message_type = 'outgoing'

        ActiveJob::Base.queue_adapter = :test
        allow(Redis::Alfred).to receive(:set).and_return(true)
        perform_enqueued_jobs(only: SendReplyJob) do
          expect { message.save! }.to have_enqueued_job(ConversationReplyEmailJob).with(message.conversation.id, kind_of(Integer)).on_queue('mailers')
        end
      end

      it 'does not schedule email for website channel if continuity is disabled' do
        inbox_without_continuity = create(:inbox, account: message.account,
                                                  channel: build(:channel_widget, account: message.account, continuity_via_email: false))
        message.inbox = inbox_without_continuity
        message.conversation.update!(inbox: inbox_without_continuity)
        message.conversation.contact.update!(email: 'test@example.com')
        message.message_type = 'outgoing'

        ActiveJob::Base.queue_adapter = :test
        expect { message.save! }.not_to have_enqueued_job(ConversationReplyEmailJob)
      end

      it 'does not schedule email for private notes' do
        message.inbox = inbox_with_continuity
        message.conversation.update!(inbox: inbox_with_continuity)
        message.conversation.contact.update!(email: 'test@example.com')
        message.private = true
        message.message_type = 'outgoing'

        ActiveJob::Base.queue_adapter = :test
        expect { message.save! }.not_to have_enqueued_job(ConversationReplyEmailJob)
      end

      it 'calls SendReplyJob for all channels' do
        allow(SendReplyJob).to receive(:perform_later).and_return(true)
        message.message_type = 'outgoing'
        message.save!
        expect(SendReplyJob).to have_received(:perform_later).with(message.id)
      end
    end
  end

  context 'when content_type is blank' do
    let(:message) { build(:message, content_type: nil, account: create(:account)) }

    it 'sets content_type as text' do
      message.save!
      expect(message.content_type).to eq 'text'
    end
  end

  context 'when processed_message_content is blank' do
    let(:message) { build(:message, content_type: :text, account: create(:account), content: 'Processed message content') }

    it 'sets content_type as text' do
      message.save!
      expect(message.processed_message_content).to eq message.content
    end
  end

  context 'when attachments size maximum' do
    let(:message) { build(:message, content_type: nil, account: create(:account)) }

    it 'add errors to message for attachment size is more than allowed limit' do
      16.times.each do
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      end

      expect(message.errors.messages).to eq({ attachments: ['exceeded maximum allowed'] })
    end
  end

  context 'when email notifiable message' do
    let(:message) { build(:message, content_type: nil, account: create(:account)) }

    it 'return false if private message' do
      message.private = true
      message.message_type = 'outgoing'
      expect(message.email_notifiable_message?).to be false
    end

    it 'return false if incoming message' do
      message.private = false
      message.message_type = 'incoming'
      expect(message.email_notifiable_message?).to be false
    end

    it 'return false if activity message' do
      message.private = false
      message.message_type = 'activity'
      expect(message.email_notifiable_message?).to be false
    end

    it 'return false if message type is template and content type is not input_csat or text' do
      message.private = false
      message.message_type = 'template'
      message.content_type = 'incoming_email'
      expect(message.email_notifiable_message?).to be false
    end

    it 'return true if not private and not incoming and message content type is input_csat or text' do
      message.private = false
      message.message_type = 'template'
      message.content_type = 'text'
      expect(message.email_notifiable_message?).to be true
    end
  end

  context 'when facebook channel with unavailable story link' do
    let(:instagram_message) { create(:message, :instagram_story_mention) }

    before do
      # stubbing the request to facebook api during the message creation
      stub_request(:get, %r{https://graph.facebook.com/.*}).to_return(status: 200, body: {
        story: { mention: { link: 'http://graph.facebook.com/test-story-mention', id: '17920786367196703' } },
        from: { username: 'Sender-id-1', id: 'Sender-id-1' },
        id: 'instagram-message-id-1234'
      }.to_json, headers: {})
    end

    it 'keeps the attachment for deleted stories' do
      expect(instagram_message.attachments.count).to eq 1
      stub_request(:get, %r{https://graph.facebook.com/.*}).to_return(status: 404)
      instagram_message.push_event_data
      expect(instagram_message.reload.attachments.count).to eq 1
    end

    it 'keeps the attachment for expired stories' do
      expect(instagram_message.attachments.count).to eq 1
      # for expired stories, the link will be empty
      stub_request(:get, %r{https://graph.facebook.com/.*}).to_return(status: 200, body: {
        story: { mention: { link: '', id: '17920786367196703' } }
      }.to_json, headers: {})
      instagram_message.push_event_data
      expect(instagram_message.reload.attachments.count).to eq 1
    end
  end

  describe '#ensure_in_reply_to' do
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation, source_id: 12_345) }

    context 'when in_reply_to is present' do
      let(:content_attributes) { { in_reply_to: message.id } }
      let(:new_message) { build(:message, conversation: conversation, content_attributes: content_attributes) }

      it 'sets in_reply_to_external_id based on the source_id of the referenced message' do
        new_message.send(:ensure_in_reply_to)
        expect(new_message.content_attributes[:in_reply_to_external_id]).to eq(message.source_id)
      end
    end

    context 'when in_reply_to is not present' do
      let(:content_attributes) { { in_reply_to_external_id: message.source_id } }
      let(:new_message) { build(:message, conversation: conversation, content_attributes: content_attributes) }

      it 'sets in_reply_to based on the source_id of the referenced message' do
        new_message.send(:ensure_in_reply_to)
        expect(new_message.content_attributes[:in_reply_to]).to eq(message.id)
      end
    end

    context 'when the referenced message is not found' do
      let(:content_attributes) { { in_reply_to: message.id + 1 } }
      let(:new_message) { build(:message, conversation: conversation, content_attributes: content_attributes) }

      it 'does not set in_reply_to_external_id' do
        new_message.send(:ensure_in_reply_to)
        expect(new_message.content_attributes[:in_reply_to_external_id]).to be_nil
      end
    end

    context 'when the source message is not found' do
      let(:content_attributes) { { in_reply_to_external_id: 'source-id-that-does-not-exist' } }
      let(:new_message) { build(:message, conversation: conversation, content_attributes: content_attributes) }

      it 'does not set in_reply_to' do
        new_message.send(:ensure_in_reply_to)
        expect(new_message.content_attributes[:in_reply_to]).to be_nil
      end
    end
  end

  describe '#content' do
    let(:conversation) { create(:conversation) }

    context 'when message is not input_csat' do
      let(:message) { create(:message, conversation: conversation, content_type: 'text', content: 'Regular message') }

      it 'returns original content' do
        expect(message.content).to eq('Regular message')
      end
    end

    context 'when message is input_csat' do
      let(:message) { create(:message, conversation: conversation, content_type: 'input_csat', content: 'Rate your experience') }

      context 'when inbox is web widget' do
        before do
          allow(message.inbox).to receive(:web_widget?).and_return(true)
        end

        it 'returns original content without survey URL' do
          expect(message.content).to eq('Rate your experience')
        end
      end

      context 'when inbox is not web widget' do
        before do
          allow(message.inbox).to receive(:web_widget?).and_return(false)
        end

        it 'returns only the stored content (clean for dashboard)' do
          expect(message.content).to eq('Rate your experience')
        end

        it 'returns only the base content without URL when survey_url stored separately' do
          message.content_attributes = { 'survey_url' => 'https://app.chatwoot.com/survey/responses/12345' }
          expect(message.content).to eq('Rate your experience')
        end
      end
    end
  end

  describe '#outgoing_content' do
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation, content_type: 'text', content: 'Regular message') }

    it 'delegates to MessageContentPresenter' do
      presenter = instance_double(MessageContentPresenter)
      allow(MessageContentPresenter).to receive(:new).with(message).and_return(presenter)
      allow(presenter).to receive(:outgoing_content).and_return('Presented content')

      expect(message.outgoing_content).to eq('Presented content')
      expect(MessageContentPresenter).to have_received(:new).with(message)
      expect(presenter).to have_received(:outgoing_content)
    end
  end

  describe '#auto_reply_email?' do
    context 'when message is not an incoming email and inbox is not email' do
      let(:conversation) { create(:conversation) }
      let(:message) { create(:message, conversation: conversation, message_type: :outgoing) }

      it 'returns false' do
        expect(message.auto_reply_email?).to be false
      end
    end

    context 'when message is an incoming email' do
      let(:email_channel) { create(:channel_email) }
      let(:email_inbox) { create(:inbox, channel: email_channel) }
      let(:conversation) { create(:conversation, inbox: email_inbox) }

      it 'returns false when auto_reply is not set to true' do
        message = create(
          :message,
          conversation: conversation,
          message_type: :incoming,
          content_type: 'incoming_email',
          content_attributes: {}
        )
        expect(message.auto_reply_email?).to be false
      end

      it 'returns true when auto_reply is set to true' do
        message = create(
          :message,
          conversation: conversation,
          message_type: :incoming,
          content_type: 'incoming_email',
          content_attributes: { email: { auto_reply: true } }
        )
        expect(message.auto_reply_email?).to be true
      end
    end

    context 'when inbox is email' do
      let(:email_channel) { create(:channel_email) }
      let(:email_inbox) { create(:inbox, channel: email_channel) }
      let(:conversation) { create(:conversation, inbox: email_inbox) }

      it 'returns false when auto_reply is not set to true' do
        message = create(
          :message,
          conversation: conversation,
          message_type: :outgoing,
          content_attributes: {}
        )
        expect(message.auto_reply_email?).to be false
      end

      it 'returns true when auto_reply is set to true' do
        message = create(
          :message,
          conversation: conversation,
          message_type: :outgoing,
          content_attributes: { email: { auto_reply: true } }
        )
        expect(message.auto_reply_email?).to be true
      end
    end
  end

  describe '#should_index?' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:message) { create(:message, conversation: conversation, account: account) }

    before do
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
      account.enable_features('advanced_search_indexing')
    end

    context 'when advanced search is not allowed globally' do
      before do
        allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
      end

      it 'returns false' do
        expect(message.should_index?).to be false
      end
    end

    context 'when advanced search feature is not enabled for account on chatwoot cloud' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        account.disable_features('advanced_search_indexing')
      end

      it 'returns false' do
        expect(message.should_index?).to be false
      end
    end

    context 'when advanced search feature is not enabled for account on self-hosted' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
        account.disable_features('advanced_search_indexing')
      end

      it 'returns true' do
        expect(message.should_index?).to be true
      end
    end

    context 'when message type is not incoming or outgoing' do
      before do
        message.message_type = 'activity'
      end

      it 'returns false' do
        expect(message.should_index?).to be false
      end
    end

    context 'when all conditions are met' do
      it 'returns true for incoming message' do
        message.message_type = 'incoming'
        expect(message.should_index?).to be true
      end

      it 'returns true for outgoing message' do
        message.message_type = 'outgoing'
        expect(message.should_index?).to be true
      end
    end
  end

  describe '#reindex_for_search callback' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }

    before do
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
      account.enable_features('advanced_search_indexing')
    end

    context 'when message should be indexed' do
      it 'calls reindex_for_search for incoming message on create' do
        message = build(:message, conversation: conversation, account: account, message_type: :incoming)
        expect(message).to receive(:reindex_for_search)
        message.save!
      end

      it 'calls reindex_for_search for outgoing message on update' do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(described_class).to receive(:reindex_for_search).and_return(true)
        # rubocop:enable RSpec/AnyInstance
        message = create(:message, conversation: conversation, account: account, message_type: :outgoing)
        expect(message).to receive(:reindex_for_search).and_return(true)
        message.update!(content: 'Updated content')
      end
    end

    context 'when message should not be indexed' do
      it 'does not call reindex_for_search for activity message' do
        message = build(:message, conversation: conversation, account: account, message_type: :activity)
        expect(message).not_to receive(:reindex_for_search)
        message.save!
      end

      it 'does not call reindex_for_search for unpaid account on cloud' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        account.disable_features('advanced_search_indexing')
        message = build(:message, conversation: conversation, account: account, message_type: :incoming)
        expect(message).not_to receive(:reindex_for_search)
        message.save!
      end

      it 'does not call reindex_for_search when advanced search is not allowed' do
        allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
        message = build(:message, conversation: conversation, account: account, message_type: :incoming)
        expect(message).not_to receive(:reindex_for_search)
        message.save!
      end
    end
  end

  describe '#reaction?' do
    let(:conversation) { create(:conversation) }

    it 'returns true when content_attributes carries is_reaction' do
      message = create(:message, conversation: conversation, content_attributes: { is_reaction: true })
      expect(message.reaction?).to be true
    end

    it 'returns false for regular messages' do
      message = create(:message, conversation: conversation, content_attributes: {})
      expect(message.reaction?).to be false
    end
  end

  describe '#deleted?' do
    let(:conversation) { create(:conversation) }

    it 'returns true when the agent deleted the message' do
      message = create(:message, conversation: conversation, content_attributes: { deleted: true })
      expect(message.deleted?).to be true
    end

    it 'returns false for regular messages' do
      message = create(:message, conversation: conversation, content_attributes: {})
      expect(message.deleted?).to be false
    end
  end

  describe '#update_under_lock!' do
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation, content_attributes: {}) }

    it 'keeps content_attributes another request wrote while this object went stale' do
      described_class.find(message.id).update!(content_attributes: { deleted: true })

      message.update_under_lock!(external_error: 'boom')

      expect(message.reload.content_attributes).to include('deleted' => true, 'external_error' => 'boom')
    end

    it 'persists changes the caller left unsaved, as a plain update! would' do
      # the template path mutates additional_attributes in place and relies on the source_id write to save it
      message.additional_attributes = { 'format_version' => 'legacy' }

      message.update_under_lock!(source_id: 'wamid.123')

      expect(message.reload.source_id).to eq('wamid.123')
      expect(message.additional_attributes).to include('format_version' => 'legacy')
    end

    it 'drops stale in-memory content_attributes rather than clobbering the row' do
      described_class.find(message.id).update!(content_attributes: { deleted: true })
      message.external_error = 'written from a stale copy'

      message.update_under_lock!(source_id: 'wamid.123')

      expect(message.reload).to be_deleted
      expect(message.external_error).to be_nil
    end
  end

  describe '.hide_removed_reactions' do
    let(:conversation) { create(:conversation) }

    it 'keeps regular non-reaction messages' do
      regular = create(:message, conversation: conversation, content: 'Hello')
      expect(conversation.messages.hide_removed_reactions).to include(regular)
    end

    it 'keeps active reactions (content present, not deleted)' do
      reaction = create(:message,
                        conversation: conversation,
                        content: '👍',
                        content_attributes: { is_reaction: true, in_reply_to_external_id: 'EXT' })
      expect(conversation.messages.hide_removed_reactions).to include(reaction)
    end

    it 'hides reactions flagged as deleted' do
      # Non-blank content here so the assertion can only succeed via the
      # `deleted: true` branch (blank-content branch is covered separately).
      removed = create(:message,
                       conversation: conversation,
                       content: '👍',
                       content_attributes: { is_reaction: true, deleted: true })
      expect(conversation.messages.hide_removed_reactions).not_to include(removed)
    end

    it 'hides reactions with blank content even when not flagged as deleted' do
      blank_reaction = create(:message,
                              conversation: conversation,
                              content: '',
                              content_attributes: { is_reaction: true })
      expect(conversation.messages.hide_removed_reactions).not_to include(blank_reaction)
    end
  end

  describe 'reactions do not trigger conversation lifecycle hooks' do
    let(:conversation) { create(:conversation) }

    it 'does not reopen a resolved conversation' do
      conversation.resolved!
      create(:message,
             conversation: conversation,
             message_type: :incoming,
             content: '👍',
             content_attributes: { is_reaction: true, in_reply_to_external_id: 'EXT' })
      expect(conversation.reload.open?).to be false
    end

    it 'does not flip a pending conversation to open' do
      pending_conv = create(:conversation, status: :pending)
      create(:message,
             conversation: pending_conv,
             message_type: :incoming,
             content: '👍',
             content_attributes: { is_reaction: true, in_reply_to_external_id: 'EXT' })
      expect(pending_conv.reload.pending?).to be true
    end

    it 'does not count toward first_reply_created_at' do
      expect(conversation.first_reply_created_at).to be_nil
      create(:message,
             conversation: conversation,
             message_type: :outgoing,
             content: '👍',
             content_attributes: { is_reaction: true, in_reply_to: 1 })
      expect(conversation.reload.first_reply_created_at).to be_nil
    end

    it 'does not push an attended conversation back into the unattended queue' do
      conversation.update!(first_reply_created_at: Time.current, waiting_since: nil)
      create(:message,
             conversation: conversation,
             message_type: :incoming,
             content: '👍',
             content_attributes: { is_reaction: true, in_reply_to_external_id: 'EXT' })
      expect(conversation.reload.waiting_since).to be_nil
    end
  end

  # A "no WhatsApp" flag is only a lookup's answer; the contact replying, or their phone
  # acknowledging a message, is proof the number exists (fazer-ai/chatwoot#877).
  describe 'clearing the no-WhatsApp flag' do
    let(:channel) do
      create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false)
    end
    let(:contact_inbox) do
      create(:contact_inbox, inbox: channel.inbox, source_id: '558588246590', whatsapp_missing_checked_at: 1.hour.ago)
    end
    let(:conversation) do
      create(:conversation, account: channel.account, inbox: channel.inbox, contact: contact_inbox.contact, contact_inbox: contact_inbox)
    end

    it 'clears it when the contact sends something' do
      create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account, message_type: :incoming)

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_nil
    end

    # The payload is what moves the banner, so it has to carry the cleared value, not the one
    # still held by the loaded association.
    it 'tells the dashboard when a reply clears it, with the cleared value' do
      conversation.update!(status: :resolved) # the reply reopens it, which broadcasts again
      conversation.contact_inbox # loaded with the old date, as a request would hold it
      payloads = []
      allow(Rails.configuration.dispatcher).to receive(:dispatch) do |event, _time, data|
        payloads << data[:conversation].push_event_data if event == Events::Types::CONVERSATION_UPDATED
      end

      create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account, message_type: :incoming)

      # Every payload after the clear, the message's own reopen and activity included, has to
      # carry it: the last one is what the dashboard keeps.
      expect(payloads).not_to be_empty
      expect(payloads.last).to include(id: conversation.display_id, whatsapp_missing_checked_at: nil)
    end

    it 'clears it when an outgoing message is delivered' do
      message = create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account,
                                 message_type: :outgoing, status: :sent)

      message.update!(status: :delivered)

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_nil
    end

    it 'clears it for a reply stamped in the second the flag was set' do
      flagged_at = Time.current.change(usec: 400_000)
      contact_inbox.update!(whatsapp_missing_checked_at: flagged_at)

      create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account, message_type: :incoming,
                       content_attributes: { external_created_at: flagged_at.to_i })

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_nil
    end

    # It may have gone to the phone the contact had before; the recheck asks about this one.
    it 'keeps it when the receipt answers a message sent before the check' do
      message = create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account,
                                 message_type: :outgoing, status: :sent, created_at: 2.hours.ago)

      message.update!(status: :delivered)

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_present
    end

    # The flag is about the phone; the contact's other thread here (a LID one) warns about it too.
    it 'clears it on the contact\'s other threads in the inbox' do
      sibling = create(:contact_inbox, contact: contact_inbox.contact, inbox: channel.inbox, source_id: '123456789012345',
                                       whatsapp_missing_checked_at: 1.hour.ago)

      create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account, message_type: :incoming)

      expect(sibling.reload.whatsapp_missing_checked_at).to be_nil
    end

    # A history import replays old traffic: it predates the lookup and proves nothing now.
    it 'keeps it when the incoming message predates the check' do
      create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account, message_type: :incoming,
                       content_attributes: { external_created_at: 2.days.ago.to_i })

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_present
    end

    it 'keeps it when an old outgoing message is imported already delivered' do
      create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account, message_type: :outgoing,
                       status: :delivered, content_attributes: { external_created_at: 2.days.ago.to_i })

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_present
    end

    # A send from the paired phone comes back as an echo born delivered, with no receipt.
    it 'keeps it when an echo of a send from the phone is born delivered' do
      create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account, message_type: :outgoing,
                       status: :delivered)

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_present
    end

    # A receipt is evidence about now, whenever the message was sent.
    it 'clears it when a live receipt arrives for a message sent before the check' do
      message = create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account,
                                 message_type: :outgoing, status: :sent,
                                 content_attributes: { external_created_at: 2.days.ago.to_i })

      message.update!(status: :delivered)

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_nil
    end

    it 'keeps it when an import replays a receipt' do
      message = create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account,
                                 message_type: :outgoing, status: :sent)

      Import::SilentWrite.wrap { message.update!(status: :delivered) }

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_present
    end

    # The server's acknowledgement is exactly what a number with no account still gets.
    it 'keeps it while outgoing messages are only sent' do
      message = create(:message, conversation: conversation, inbox: channel.inbox, account: channel.account,
                                 message_type: :outgoing, status: :sent)

      message.update!(content: 'edited')

      expect(contact_inbox.reload.whatsapp_missing_checked_at).to be_present
    end
  end
end
