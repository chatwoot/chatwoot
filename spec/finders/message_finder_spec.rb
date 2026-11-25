require 'rails_helper'

describe MessageFinder do
  subject(:message_finder) { described_class.new(conversation, params) }

  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:contact) { create(:contact, email: nil) }
  let!(:conversation) do
    create(:conversation, account: account, inbox: inbox, assignee: user, contact: contact)
  end

  before do
    create(:message, account: account, inbox: inbox, conversation: conversation)
    create(:message, message_type: 'activity', account: account, inbox: inbox, conversation: conversation)
    create(:message, message_type: 'activity', account: account, inbox: inbox, conversation: conversation)
    # this outgoing message creates 2 additional messages because of the email hook execution service
    create(:message, message_type: 'outgoing', account: account, inbox: inbox, conversation: conversation)
  end

  describe '#perform' do
    context 'with filter_internal_messages false' do
      let(:params) { { filter_internal_messages: false } }

      it 'filter conversations by status' do
        result = message_finder.perform
        expect(result.count).to be 6
      end
    end

    context 'with filter_internal_messages true' do
      let(:params) { { filter_internal_messages: true } }

      it 'filter conversations by status' do
        result = message_finder.perform
        expect(result.count).to be 4
      end
    end

    context 'with before attribute' do
      let!(:outgoing) { create(:message, message_type: 'outgoing', account: account, inbox: inbox, conversation: conversation) }
      let(:params) { { before: outgoing.id } }

      it 'filter conversations by status' do
        result = message_finder.perform
        expect(result.count).to be 6
      end
    end

    context 'with a before attribute above the message id range' do
      let!(:max_id_message) do
        create(:message, id: described_class::MESSAGE_ID_MAX, account: account, inbox: inbox, conversation: conversation)
      end
      let(:params) { { before: 4_611_686_018_427_387_903 } }

      it 'includes the maximum valid message id without overflowing the database column' do
        expect(message_finder.perform).to include(max_id_message)
      end
    end

    context 'with after attribute' do
      let(:params) { { after: conversation.messages.first.id } }

      it 'filter conversations by status' do
        result = message_finder.perform
        expect(result.count).to be 5
        expect(result.first.id).to be conversation.messages.second.id
        expect(result.last.message_type).to eq 'outgoing'
      end
    end

    # A history import stamps `created_at` from when the message was sent and takes its id
    # from the INSERT, so for a thread carrying imported rows the two orders disagree.
    # Ordering the catch-up by time cut a different set than the id filter chose, and the
    # client moved its cursor past the rows that answer left out.
    context 'when a backdated row was written after the ones already on screen' do
      let!(:cursor) { conversation.messages.maximum(:id) }
      let!(:live) { create(:message, account: account, inbox: inbox, conversation: conversation, created_at: 1.minute.ago) }
      let!(:imported) { create(:message, account: account, inbox: inbox, conversation: conversation, created_at: 2.days.ago) }
      let(:params) { { after: cursor } }

      it 'answers in id order, which is the order the cursor advances in' do
        expect(message_finder.perform.map(&:id)).to eq([live.id, imported.id])
      end

      it 'cuts the window by id, so what it leaves out is what the next call asks for' do
        stub_const("#{described_class}::CATCH_UP_LIMIT", 1)

        expect(message_finder.perform.map(&:id)).to eq([live.id])
      end
    end

    context 'with an after attribute above the message id range' do
      let(:params) { { after: 881_965_304_328 } }

      it 'returns no messages without overflowing the database column' do
        expect(message_finder.perform).to be_empty
      end
    end

    context 'with after and before attribute' do
      let(:params) do
        {
          after: conversation.messages.first.id,
          before: conversation.messages.last.id
        }
      end

      it 'filter conversations by status' do
        result = message_finder.perform
        expect(result.count).to be 5
        expect(result.last.id).to be conversation.messages[-2].id
      end
    end

    context 'with after and before attributes above the message id range' do
      let!(:max_id_message) do
        create(:message, id: described_class::MESSAGE_ID_MAX, account: account, inbox: inbox, conversation: conversation)
      end
      let(:params) do
        {
          after: 881_965_304_328,
          before: 4_611_686_018_427_387_903
        }
      end

      it 'returns no messages' do
        result = message_finder.perform

        expect(result).to be_empty
        expect(result).not_to include(max_id_message)
      end
    end
  end

  # Imported history is written in the order the provider hands it over, which is not the
  # order it happened: a message delivered late gets the next id and an older timestamp.
  # An id-only cursor would drop it from every page, including the ones reached by
  # scrolling up.
  describe 'a message written out of chronological order' do
    let(:params) { {} }
    let!(:newest) do
      create(:message, account: account, inbox: inbox, conversation: conversation,
                       content: 'sent last', created_at: 2.minutes.ago)
    end
    # Higher id, earlier timestamp: this is the shape a late history frame takes.
    let!(:late_arrival) do
      create(:message, account: account, inbox: inbox, conversation: conversation,
                       content: 'sent first, stored last', created_at: 3.minutes.ago)
    end

    it 'is reachable from a cursor anchored on the newer message' do
      result = described_class.new(conversation, { before: newest.id }).perform

      expect(late_arrival.id).to be > newest.id
      expect(result).to include(late_arrival)
      expect(result).not_to include(newest)
    end

    # The cursor now means a point in time, so a message with a *lower* id that happened
    # after it is excluded. Under the id filter it would have come back as "before".
    it 'excludes the cursor and everything that happened after it' do
      result = described_class.new(conversation, { before: late_arrival.id }).perform

      expect(newest.id).to be < late_arrival.id
      expect(result).not_to include(late_arrival, newest)
    end

    # The cursor names a message this conversation does not have, so there is no timestamp
    # to compare against and the id filter is all that is left.
    it 'falls back to the id filter for a cursor from another conversation' do
      elsewhere = create(:conversation, account: account, inbox: inbox, contact: contact)
      foreign = create(:message, account: account, inbox: inbox, conversation: elsewhere)

      result = described_class.new(conversation, { before: foreign.id }).perform

      expect(result).to include(newest, late_arrival)
    end
  end

  # WhatsApp timestamps have second resolution and a burst lands inside one; imported
  # history concentrates it further, since every row is backdated to when it was sent. Once
  # more than a page of messages share a second, the window's ordering stops being a
  # presentation detail: it picks which of the tied rows the page shows, and the cursor
  # decides what the next page starts below. While the two ranked ties differently,
  # whatever the window left out and the cursor excluded was in the conversation and on no
  # page at all.
  describe 'more messages than fit on a page share one second' do
    let!(:fresh_conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
    let(:burst_at) { 3.hours.ago.change(usec: 0) }
    let!(:burst) do
      Array.new(MessageFinder::PAGE_LIMIT + 5) do |index|
        create(:message, account: account, inbox: inbox, conversation: fresh_conversation,
                         content: "burst #{index}", created_at: burst_at)
      end
    end

    # The first incoming message on a conversation whose contact has no email adds two
    # `template` rows carrying the current time, so the burst is not the whole thread. That
    # is left in rather than tuned away: a real thread has rows on both sides of the tie,
    # and the window has to rank the tied ones against each other and against those.
    def page_after(cursor)
      described_class.new(fresh_conversation, cursor.nil? ? {} : { before: cursor }).perform.to_a
    end

    # Stated without naming a row count, so it says which rows belong on the page rather
    # than restating the query that builds it: a tied message left off the newest page can
    # only be one that ranks below every tied message on it.
    it 'ranks the tied messages by id when it picks the page' do
      shown = page_after(nil).map(&:id)
      on_page, off_page = burst.map(&:id).partition { |id| shown.include?(id) }

      expect(on_page).to be_present
      expect(off_page).to be_present
      expect(on_page.min).to be > off_page.max
    end

    it 'reaches every message by scrolling up, without repeating one' do
      seen = []
      cursor = nil

      # Bounded so a cursor that stops advancing fails as a wrong answer rather than
      # hanging the suite.
      (fresh_conversation.messages.count + 2).times do
        page = page_after(cursor)
        break if page.empty?

        seen.concat(page.map(&:id))
        cursor = page.first.id
      end

      expect(seen).to match_array(fresh_conversation.messages.pluck(:id))
    end
  end

  describe 'page_window with reactions' do
    # Isolated setup: skip the shared `before` block's fixtures so count assertions stay stable.
    subject(:message_finder) { described_class.new(fresh_conversation, {}) }

    let!(:fresh_conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }

    it 'does not let reactions consume the 20-item page limit' do
      # 22 non-reaction messages plus a handful of reactions interleaved.
      # Without the non-reaction-based pick, the trailing reactions could push
      # real messages off the page.
      regular_messages = []
      22.times do |i|
        regular_messages << create(:message, conversation: fresh_conversation, content: "msg #{i}")
      end
      5.times do |i|
        create(:message,
               conversation: fresh_conversation,
               content: '👍',
               content_attributes: { is_reaction: true, in_reply_to_external_id: "ext_#{i}" })
      end

      result = message_finder.perform
      non_reactions = result.reject { |m| m.content_attributes['is_reaction'] }

      # The latest non-reactions must be present even though 5 reactions came
      # after them — the page is anchored on non-reactions, not raw position.
      expect(non_reactions).to include(regular_messages.last)
      # And the page yields at least 20 non-reactions (anchor is the 20th
      # newest non-reaction, plus any newer ones). No early truncation.
      expect(non_reactions.size).to be >= 20
    end

    it 'includes reactions whose parent message is inside the visible window' do
      msg = create(:message, conversation: fresh_conversation, content: 'Hi', source_id: 'wamid.parent')
      attached_reaction = create(:message,
                                 conversation: fresh_conversation,
                                 content: '🔥',
                                 content_attributes: { is_reaction: true, in_reply_to_external_id: 'wamid.parent' })
      orphan_reaction = create(:message,
                               conversation: fresh_conversation,
                               content: '👍',
                               content_attributes: { is_reaction: true, in_reply_to_external_id: 'wamid.older.not.in.window' })

      result = message_finder.perform

      expect(result).to include(msg, attached_reaction)
      expect(result).not_to include(orphan_reaction)
    end

    it 'returns an empty scope when no non-reaction messages exist' do
      create(:message,
             conversation: fresh_conversation,
             content: '👍',
             content_attributes: { is_reaction: true, in_reply_to_external_id: 'ext_orphan' })

      expect(message_finder.perform).to be_empty
    end
  end
end
