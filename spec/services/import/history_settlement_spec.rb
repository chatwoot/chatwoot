require 'rails_helper'

# The shared settlement, exercised through a stand-in includer rather than through one of
# the importers: what is worth pinning is the rule, and each importer hands it the same
# thing -- a conversation and the rows written into it.
describe Import::HistorySettlement do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:group) { create(:contact, account: account, name: 'Grupo') }
  let(:conversation) do
    contact_inbox = create(:contact_inbox, contact: group, inbox: inbox)
    create(:conversation, account: account, inbox: inbox, contact: group, contact_inbox: contact_inbox)
  end

  # A backfill's shape: it names a batch size, which is how it says it has taken the search
  # index on itself. An importer that has not is covered separately below.
  let(:settler) do
    Class.new do
      include Import::HistorySettlement
      attr_reader :opened

      def initialize = @opened = Set.new
      def announcing(&) = yield
      def run(rows) = settle(rows, [])
      def run_contacts(conversation, rows) = stamp_contact(conversation, rows)
      def search_index_batch = 1
    end
  end

  # Written the way an importer writes, because the live `update_contact_activity` would
  # otherwise stamp every sender with `DateTime.now` and hide whatever the settlement did.
  def incoming(sender, at)
    Import::SilentWrite.wrap do
      create(:message, account: account, inbox: inbox, conversation: conversation,
                       message_type: :incoming, sender: sender, created_at: at,
                       content_attributes: { imported: true })
    end
  end

  # On a group the conversation's contact is the group and each row was written by a
  # participant. Stamping the conversation's contact gives the group a clock it never
  # earned and leaves every participant at null.
  describe 'when the conversation is a group and the rows are its participants' do
    let(:ana) { create(:contact, account: account, name: 'Ana') }
    let(:bruno) { create(:contact, account: account, name: 'Bruno') }

    it 'stamps each participant from what that participant wrote' do
      rows = [incoming(ana, Time.zone.parse('2023-05-01 10:00')),
              incoming(bruno, Time.zone.parse('2023-06-10 09:00')),
              incoming(ana, Time.zone.parse('2023-03-01 08:00'))]
      settler.new.run(rows)
      expect(ana.reload.last_activity_at).to eq(Time.zone.parse('2023-05-01 10:00'))
      expect(bruno.reload.last_activity_at).to eq(Time.zone.parse('2023-06-10 09:00'))
    end

    it 'leaves the group itself alone, since the group never wrote anything' do
      settler.new.run([incoming(ana, Time.zone.parse('2023-05-01 10:00'))])
      expect(group.reload.last_activity_at).to be_nil
    end
  end

  it 'never drags a contact backwards, whoever wrote the row' do
    ana = create(:contact, account: account, last_activity_at: Time.zone.parse('2026-01-01 09:00'))
    settler.new.run([incoming(ana, Time.zone.parse('2023-05-01 10:00'))])
    expect(ana.reload.last_activity_at).to eq(Time.zone.parse('2026-01-01 09:00'))
  end

  # Being searchable is most of why an archive is imported. The per-row callback is stopped
  # in the guards precisely so the batch can go over in one pass, so the pass has to exist.
  describe 'handing the batch to the search index' do
    let(:ana) { create(:contact, account: account, name: 'Ana') }
    let(:rows) do
      [incoming(ana, Time.zone.parse('2023-05-01 10:00')),
       incoming(ana, Time.zone.parse('2023-05-02 10:00'))]
    end

    it 'asks for one bulk pass over the whole batch, not one job per row' do
      # `reindex` reaches a relation through ActiveRecord's delegation to the class, so a
      # verifying double refuses it: the method is not defined on Relation.
      relation = double('Message relation') # rubocop:disable RSpec/VerifiedDoubles
      written = rows
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
      allow(Message).to receive(:where).with(id: written.map(&:id)).and_return(relation)
      expect(relation).to receive(:reindex).with(mode: :async)
      settler.new.run(written)
    end

    # The IMAP importer settles inside the transaction that writes the row. Enqueued there,
    # a worker is free to run the job before the row exists, find nothing, and leave it out
    # of the index for good -- the per-row callback that would have caught it later is the
    # one this replaced.
    it 'waits for the transaction the importer settles inside to commit' do
      relation = double('Message relation') # rubocop:disable RSpec/VerifiedDoubles
      written = rows
      indexed = false
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
      allow(Message).to receive(:where).with(id: written.map(&:id)).and_return(relation)
      allow(relation).to receive(:reindex) { indexed = true }

      ActiveRecord::Base.transaction do
        settler.new.run(written)
        expect(indexed).to be(false)
      end
      expect(indexed).to be(true)
    end

    # Searchkick splits rows within one `reindex` call and not across calls, so a job per
    # settlement is a job per message wherever a settlement is one message -- which is the
    # IMAP path, and which is the flood the guard was put in to stop.
    describe 'an importer that outlives its settlements' do
      let(:buffering) do
        Class.new do
          include Import::HistorySettlement
          attr_reader :opened

          def initialize = @opened = Set.new
          def announcing(&) = yield
          def run(rows) = settle(rows, [])
          def search_index_batch = 3
        end
      end

      let(:ana) { create(:contact, account: account, name: 'Ana') }

      # Turned on only once the rows exist. An importer that has not taken the index on
      # itself keeps Message's own per-row callback, which is the point of the guard now, so
      # writing the fixtures under the stub would be exercising that callback instead.
      def watch
        relation = double('Message relation') # rubocop:disable RSpec/VerifiedDoubles
        allow(relation).to receive(:reindex)
        allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
        calls = []
        allow(Message).to receive(:where) do |args|
          calls << args[:id]
          relation
        end
        calls
      end

      it 'sends one pass for the batch instead of one per settlement' do
        written = Array.new(3) { |i| incoming(ana, Time.zone.parse('2023-05-01 10:00') + i.days) }
        calls = watch
        importer = buffering.new
        written.each { |row| importer.run([row]) }

        expect(calls).to eq([written.map(&:id)])
      end

      it 'sends what is still owed when the run says it is over' do
        written = Array.new(2) { |i| incoming(ana, Time.zone.parse('2023-05-01 10:00') + i.days) }
        calls = watch
        importer = buffering.new
        written.each { |row| importer.run([row]) }
        expect(calls).to be_empty

        importer.flush_search_index
        expect(calls).to eq([written.map(&:id)])
      end

      # The rows are committed and the next pass skips them as already stored, so a batch
      # dropped on a failed handoff is a batch nothing ever indexes again.
      it 'keeps what it could not hand over' do
        written = Array.new(2) { |i| incoming(ana, Time.zone.parse('2023-05-01 10:00') + i.days) }
        relation = double('Message relation') # rubocop:disable RSpec/VerifiedDoubles
        allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
        allow(Message).to receive(:where).and_return(relation)
        allow(relation).to receive(:reindex).and_raise(Redis::CannotConnectError)
        importer = buffering.new
        written.each { |row| importer.run([row]) }

        expect { importer.flush_search_index }.to raise_error(Redis::CannotConnectError)
        allow(relation).to receive(:reindex)
        importer.flush_search_index
        expect(relation).to have_received(:reindex).twice
      end

      # The threshold flush fires inside the mail importer's transaction, carrying ids from
      # hundreds of messages that committed long before it. Rails discards an after_commit
      # callback when the transaction rolls back, so clearing the backlog up front would
      # lose every one of them -- their per-row callback was suppressed and every later pass
      # skips them as already stored.
      it 'keeps what a rolled back transaction never handed over' do
        written = Array.new(2) { |i| incoming(ana, Time.zone.parse('2023-05-01 10:00') + i.days) }
        calls = watch
        importer = buffering.new
        written.each { |row| importer.run([row]) }

        ActiveRecord::Base.transaction do
          importer.flush_search_index
          raise ActiveRecord::Rollback
        end
        expect(calls).to be_empty

        importer.flush_search_index
        expect(calls).to eq([written.map(&:id)])
      end

      # A resumed OctaDesk ticket settles from the whole conversation, so the same row is
      # offered again by the next settlement in the same batch.
      it 'asks for a row once however many settlements named it' do
        row = incoming(ana, Time.zone.parse('2023-05-01 10:00'))
        calls = watch
        importer = buffering.new
        3.times { importer.run([row]) }

        expect(calls).to eq([[row.id]])
      end
    end

    # An importer handed a webhook's worth of rows and thrown away keeps Message's own
    # per-row callback, which the guard leaves alone for it. Indexing here as well would be
    # the same rows twice, and buffering here would lose the ones a batch committed before
    # it raised: they never reach a settlement, and the retry filters them out as stored.
    it 'leaves it to the callback for an importer that has not taken it on' do
      passive = Class.new do
        include Import::HistorySettlement
        attr_reader :opened

        def initialize = @opened = Set.new
        def announcing(&) = yield
        def run(rows) = settle(rows, [])
      end
      written = rows
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
      expect(Message).not_to receive(:where)
      passive.new.run(written)
    end

    # `reindex` is not defined at all unless `searchkick` was declared, which is itself
    # conditional on the same test.
    it 'leaves the index alone where advanced search is not configured' do
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)
      expect(Message).not_to receive(:where)
      settler.new.run(rows)
    end
  end

  # The resume path reads the thread back off the database, where `sender` on every row is
  # a query. Read off `sender_id` the batch costs one.
  it 'asks for the contacts once for the whole batch' do
    rows = Array.new(6) { |i| incoming(create(:contact, account: account), Time.zone.parse('2023-05-01 10:00') + i.days) }
    reloaded = conversation.messages.reload.to_a
    queries = 0
    subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      queries += 1 if payload[:sql].start_with?('SELECT') && payload[:sql].include?('"contacts"')
    end
    settler.new.run_contacts(conversation, reloaded)
    ActiveSupport::Notifications.unsubscribe(subscription)
    expect(rows.length).to eq(6)
    expect(queries).to eq(1)
  end
end
