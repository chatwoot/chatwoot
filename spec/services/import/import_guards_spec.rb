require 'rails_helper'

# The guards live in an initializer and are prepended at boot; what is worth covering is
# which level each one reads, because getting that wrong is silent in both directions.
describe 'ImportGuards' do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_email, account: account) }
  let(:inbox) { channel.inbox }
  let(:contact_inbox) do
    ContactInboxWithContactBuilder.new(source_id: 'quem@example.com', inbox: inbox,
                                       contact_attributes: { name: 'Quem', email: 'quem@example.com' }).perform
  end

  def new_conversation
    Conversation.create!(account_id: account.id, inbox_id: inbox.id,
                         contact_id: contact_inbox.contact_id, contact_inbox_id: contact_inbox.id)
  end

  context 'when the inbox has an active agent bot' do
    before do
      bot = create(:agent_bot, account: account)
      create(:agent_bot_inbox, inbox: inbox, agent_bot: bot, status: :active)
      inbox.reload
    end

    it 'starts a conversation pending outside an import, as it always has' do
      expect(new_conversation.status).to eq('pending')
    end

    # An archive thread is created resolved on purpose: born in that state it fires no
    # resolution event and lands in no report. The bot override would undo that for the
    # whole archive at once.
    it 'leaves the status alone while writing an archive' do
      conversation = Import::SilentWrite.wrap { new_conversation }
      expect(conversation.status).to eq('open')
      expect(conversation.assignee_agent_bot_id).to be_nil
    end

    # A gap thread is live work recovered a minute late, and has to be routed like any
    # other arrival or nobody works it until they reload.
    it 'routes a gap thread the way an arrival would be' do
      conversation = Import::SilentWrite.wrap(announce: true) { new_conversation }
      expect(conversation.status).to eq('pending')
      expect(conversation.assignee_agent_bot_id).to be_present
    end

    it 'still resolves a blocked contact at either level, which is not the import to undo' do
      contact_inbox.contact.update!(blocked: true)
      archived = Import::SilentWrite.wrap { new_conversation }
      announced = Import::SilentWrite.wrap(announce: true) { new_conversation }
      expect([archived.status, announced.status]).to eq(%w[resolved resolved])
    end
  end

  # `create_activity` does not act, it enqueues: the job creates a real Message on a Sidekiq
  # thread, where the flag is gone and every callback runs live -- the dispatcher, the bot,
  # the index, and `last_activity_at` moved to the time of the import. A thread from 2021
  # would arrive at the top of the inbox wearing today's date and a line nobody wrote.
  describe 'the activity line a conversation writes about itself' do
    # Reached at all only because these examples name an actor. Nothing in the import does:
    # `create_label_change` returns unless something named one, and a rake task leaves
    # `Current` empty. That is ambient state the import does not control -- the same importer
    # driven from a request carries the operator in `Current.user` -- so the guard is written
    # against the callback rather than against the one call that reaches it today.
    let(:operator) { create(:user, account: account) }

    before { Current.user = operator }

    after { Current.reset }

    it 'is enqueued outside an import, as it always has been' do
      conversation = new_conversation
      expect { conversation.add_labels(['suporte']) }.to have_enqueued_job(Conversations::ActivityMessageJob)
    end

    # Both levels, unlike the guards around it: the job runs where no level reaches, so an
    # announcing run would hand the event to every listener a second after the sync
    # dispatcher let exactly one of them through.
    it 'is not enqueued at either level of the flag' do
      archived = new_conversation
      announced = new_conversation

      expect { Import::SilentWrite.wrap { archived.add_labels(['suporte']) } }
        .not_to have_enqueued_job(Conversations::ActivityMessageJob)
      expect { Import::SilentWrite.wrap(announce: true) { announced.add_labels(['suporte']) } }
        .not_to have_enqueued_job(Conversations::ActivityMessageJob)
    end

    it 'still writes the labels it was asked for' do
      conversation = new_conversation
      Import::SilentWrite.wrap { conversation.add_labels(%w[suporte reembolso]) }
      expect(conversation.reload.label_list).to match_array(%w[suporte reembolso])
    end
  end

  # Not exercised through Message: `should_index?` is false unless advanced search is
  # configured at boot, so a create-a-message test would pass with the guard deleted. What
  # is checkable without a cluster is that the guard is on the method Message actually
  # defines, and that it reads both levels.
  describe 'the per-row search index job' do
    it 'is prepended over the callback Message defines' do
      expect(Message.private_method_defined?(:reindex_for_search)).to be(true)
      expect(Message.ancestors.index(ImportGuards::SilentSearchIndex))
        .to be < Message.ancestors.index(Message)
    end

    # Not the level: the question is who indexes, not how loud the write is. A writer that
    # has not taken it on keeps the callback, and needs it -- a batch of its that raised
    # after some rows committed never reaches a settlement, and the retry filters those rows
    # out as already stored, so this is the only thing that would ever index them.
    it 'stops the per-row reindex only for a writer that indexes its own rows' do
      indexed = Class.new { def reindex_for_search = :indexed }
      indexed.prepend(ImportGuards::SilentSearchIndex)
      row = indexed.new

      expect(row.send(:reindex_for_search)).to eq(:indexed)
      expect(Import::SilentWrite.wrap { row.send(:reindex_for_search) }).to eq(:indexed)
      expect(Import::SilentWrite.wrap(announce: true) { row.send(:reindex_for_search) }).to eq(:indexed)
      expect(Import::SilentWrite.wrap(indexing: true) { row.send(:reindex_for_search) }).to be_nil
      expect(Import::SilentWrite.wrap(announce: true, indexing: true) { row.send(:reindex_for_search) }).to be_nil
    end
  end

  # A prepended module publishes what it defines, so a guard that forgot to restate the
  # visibility would widen the model's public surface as a side effect of narrowing its
  # behaviour. Read off the models rather than off the modules, because it is the model's
  # surface that is the claim.
  describe 'the public surface of the guarded models' do
    it 'leaves every guarded callback as private as it was' do
      surface = {
        Message => %i[execute_after_create_commit_callbacks hold_pending_scheduled_messages reindex_for_search],
        Conversation => %i[run_auto_assignment set_active_bot_conversation],
        Contact => %i[ip_lookup]
      }
      leaked = surface.flat_map { |klass, names| names.reject { |name| klass.private_method_defined?(name) } }
      expect(leaked).to be_empty
    end

    it 'leaves the one that was already public alone' do
      expect(Contact.public_method_defined?(:fetch_avatar_from_gravatar)).to be(true)
    end
  end

  describe 'the jobs a new contact would start on its own' do
    it 'skips the Gravatar fetch for an archive, where one request per contact is a flood' do
      expect do
        Import::SilentWrite.wrap do
          create(:contact, account: account, email: "arquivo-#{SecureRandom.hex(4)}@example.com")
        end
      end.not_to have_enqueued_job(Avatar::AvatarFromGravatarJob)
    end

    it 'fetches it for a gap contact, where it is one request like any arrival' do
      expect do
        Import::SilentWrite.wrap(announce: true) do
          create(:contact, account: account, email: "gap-#{SecureRandom.hex(4)}@example.com")
        end
      end.to have_enqueued_job(Avatar::AvatarFromGravatarJob)
    end
  end

  # `hold_on_reply` means "if the customer writes back first, do not send this". A row that
  # is incoming, public and not a reaction is the whole trigger, and an imported row passes
  # that test the same way a live one does.
  describe 'a scheduled message waiting on the customer to reply' do
    let(:conversation) { new_conversation }
    let(:scheduled) do
      create(:scheduled_message, account: account, inbox: inbox, conversation: conversation,
                                 scheduled_at: 2.days.from_now, hold_on_reply: true, status: :pending)
    end

    def import(created_at, **level)
      Import::SilentWrite.wrap(**level) do
        create(:message, account: account, inbox: inbox, conversation: conversation,
                         message_type: :incoming, content: 'historia', created_at: created_at)
      end
    end

    it 'holds it when a live reply arrives, which is what the flag is for' do
      scheduled
      create(:message, account: account, inbox: inbox, conversation: conversation,
                       message_type: :incoming, content: 'oi')
      expect(scheduled.reload.status).to eq('held')
    end

    # The archive row is years old, so `scheduled_at > created_at` is true of every pending
    # scheduled message in the account: one imported ticket would hold the lot.
    it 'leaves it alone while writing an archive' do
      scheduled
      import(3.years.ago)
      expect(scheduled.reload.status).to eq('pending')
    end

    # A gap row is a reply that did arrive, just late. Holding is the right answer there.
    it 'holds it for a gap row, which is a real reply we learned about late' do
      scheduled
      import(1.minute.ago, announce: true)
      expect(scheduled.reload.status).to eq('held')
    end
  end

  describe 'the fan-out around a written message' do
    it 'reaches nothing at either level' do
      conversation = Import::SilentWrite.wrap { new_conversation }
      expect do
        Import::SilentWrite.wrap do
          create(:message, account: account, inbox: inbox, conversation: conversation,
                           message_type: :incoming, content: 'historia')
        end
      end.not_to have_enqueued_job(EventDispatcherJob)
    end
  end
end
