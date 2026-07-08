require 'rails_helper'

RSpec.describe Captain::AssistantStatsBuilder do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }

  before { create(:captain_inbox, captain_assistant: assistant, inbox: inbox) }

  describe '#metrics' do
    # Two conversations handled in the current 30-day window, one in the previous.
    let(:current_convo_a) { create(:conversation, account: account, inbox: inbox) }
    let(:current_convo_b) { create(:conversation, account: account, inbox: inbox) }
    let(:previous_convo) { create(:conversation, account: account, inbox: inbox) }

    before do
      [current_convo_a, current_convo_b].each do |conversation|
        create(:message, account: account, inbox: inbox, conversation: conversation,
                         sender: assistant, message_type: :outgoing, private: false, created_at: 5.days.ago)
      end
      create(:message, account: account, inbox: inbox, conversation: previous_convo,
                       sender: assistant, message_type: :outgoing, private: false, created_at: 45.days.ago)
    end

    it 'returns every metric for the current and previous window' do
      metrics = described_class.new(assistant, '30').metrics

      expect(metrics.keys).to contain_exactly(
        :conversations_handled, :auto_resolution_rate, :handoff_rate,
        :hours_saved, :reopen_rate, :conversation_depth, :knowledge
      )
      expect(metrics[:conversations_handled]).to include(:current, :previous, :trend)
    end

    it 'counts distinct handled conversations per window and the percent trend' do
      handled = described_class.new(assistant, '30').metrics[:conversations_handled]

      expect(handled[:current]).to eq(2)
      expect(handled[:previous]).to eq(1)
      expect(handled[:trend]).to eq(100.0)
    end

    it 'derives auto-resolution and handoff rates from reporting events on the handled set' do
      create(:reporting_event, account: account, conversation: current_convo_a,
                               name: 'conversation_captain_inference_resolved')
      create(:reporting_event, account: account, conversation: current_convo_b,
                               name: 'conversation_captain_inference_handoff')

      metrics = described_class.new(assistant, '30').metrics

      expect(metrics[:auto_resolution_rate][:current]).to eq(50.0)
      expect(metrics[:handoff_rate][:current]).to eq(50.0)
    end

    it 'does not count a bot resolve as an auto-resolution when the conversation was handed off' do
      # convo_a: handoff, customer goes quiet, resolve lands without an agent message, so the
      # listener still emits conversation_bot_resolved for the handed-off conversation. It must
      # not count as an auto-resolution, but still counts as a handoff.
      create(:reporting_event, account: account, conversation: current_convo_a,
                               name: 'conversation_bot_handoff')
      create(:reporting_event, account: account, conversation: current_convo_a,
                               name: 'conversation_bot_resolved')
      # convo_b: a clean bot resolve with no handoff still counts, so the exclusion is scoped
      # to handed-off conversations and doesn't drop every bot resolve.
      create(:reporting_event, account: account, conversation: current_convo_b,
                               name: 'conversation_bot_resolved')

      metrics = described_class.new(assistant, '30').metrics

      expect(metrics[:auto_resolution_rate][:current]).to eq(50.0)
      expect(metrics[:handoff_rate][:current]).to eq(50.0)
    end

    it 'still counts an inference resolve when the conversation was also handed off' do
      create(:reporting_event, account: account, conversation: current_convo_a,
                               name: 'conversation_captain_inference_handoff')
      create(:reporting_event, account: account, conversation: current_convo_a,
                               name: 'conversation_captain_inference_resolved')

      metrics = described_class.new(assistant, '30').metrics

      expect(metrics[:auto_resolution_rate][:current]).to eq(50.0)
      expect(metrics[:handoff_rate][:current]).to eq(50.0)
    end

    it 'excludes resolution events that fall outside the current window' do
      create(:reporting_event, account: account, conversation: current_convo_a,
                               name: 'conversation_captain_inference_resolved', created_at: 60.days.ago)

      metrics = described_class.new(assistant, '30').metrics

      expect(metrics[:auto_resolution_rate][:current]).to eq(0.0)
    end

    it 'computes conversation depth as public replies per handled conversation' do
      depth = described_class.new(assistant, '30').metrics[:conversation_depth]

      # 2 public outgoing replies across 2 distinct conversations in the current window.
      expect(depth[:current]).to eq(1.0)
    end

    it 'ignores private notes and incoming messages when counting public replies' do
      create(:message, account: account, inbox: inbox, conversation: current_convo_a,
                       sender: assistant, message_type: :outgoing, private: true, created_at: 5.days.ago)

      depth = described_class.new(assistant, '30').metrics[:conversation_depth]

      expect(depth[:current]).to eq(1.0)
    end
  end

  describe 'range handling' do
    it 'accepts the allowed day and named ranges' do
      %w[7 30 90 this_month last_month].each do |allowed|
        expect(described_class.new(assistant, allowed).range).to eq(allowed)
      end
    end

    it 'falls back to the default range for values outside the allowed set' do
      expect(described_class.new(assistant, '365000').range).to eq('30')
      expect(described_class.new(assistant, 'bogus').range).to eq('30')
      expect(described_class.new(assistant, nil).range).to eq('30')
    end
  end

  describe '#metrics reopen_rate' do
    # A conversation the assistant handled (messaged) inside the current 30-day window.
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    before do
      create(:message, account: account, inbox: inbox, conversation: conversation,
                       sender: assistant, message_type: :outgoing, private: false, created_at: 8.days.ago)
    end

    it 'counts a reopen that happened after the captain resolve' do
      create(:reporting_event, account: account, inbox: inbox, conversation: conversation,
                               name: 'conversation_bot_resolved', event_start_time: 6.days.ago, event_end_time: 6.days.ago)
      create(:reporting_event, account: account, inbox: inbox, conversation: conversation,
                               name: 'conversation_opened', value: 120, event_start_time: 6.days.ago, event_end_time: 4.days.ago)

      expect(described_class.new(assistant, '30').metrics[:reopen_rate][:current]).to eq(100.0)
    end

    it 'ignores a human resolve/reopen that happened before the captain resolve' do
      # Earlier resolve/reopen cycle, then Captain resolves later in the same window.
      create(:reporting_event, account: account, inbox: inbox, conversation: conversation,
                               name: 'conversation_opened', value: 120, event_start_time: 20.days.ago, event_end_time: 18.days.ago)
      create(:reporting_event, account: account, inbox: inbox, conversation: conversation,
                               name: 'conversation_bot_resolved', event_start_time: 5.days.ago, event_end_time: 5.days.ago)

      expect(described_class.new(assistant, '30').metrics[:reopen_rate][:current]).to eq(0.0)
    end

    it 'counts an evaluated-path reopen when bot_resolved is skipped and the inference event is newer' do
      # Prior human reply => create_bot_resolved_event skips conversation_bot_resolved, so the cohort
      # only holds the inference event, which is dispatched a moment after the generic conversation_resolved
      # that seeds the reopen's event_start_time. The match must use the reopen's actual reopen time.
      create(:reporting_event, account: account, inbox: inbox, conversation: conversation,
                               name: 'conversation_captain_inference_resolved',
                               event_start_time: 6.days.ago, event_end_time: 6.days.ago + 1.second)
      create(:reporting_event, account: account, inbox: inbox, conversation: conversation,
                               name: 'conversation_opened', value: 120, event_start_time: 6.days.ago, event_end_time: 3.days.ago)

      expect(described_class.new(assistant, '30').metrics[:reopen_rate][:current]).to eq(100.0)
    end

    it 'counts both inference and time-based bot resolves in the denominator' do
      # conversation: inference-resolved and reopened
      create(:reporting_event, account: account, inbox: inbox, conversation: conversation,
                               name: 'conversation_captain_inference_resolved', event_start_time: 6.days.ago, event_end_time: 6.days.ago)
      create(:reporting_event, account: account, inbox: inbox, conversation: conversation,
                               name: 'conversation_opened', value: 120, event_start_time: 6.days.ago, event_end_time: 4.days.ago)
      # other: time-based bot-resolved, never reopened
      other = create(:conversation, account: account, inbox: inbox)
      create(:message, account: account, inbox: inbox, conversation: other,
                       sender: assistant, message_type: :outgoing, private: false, created_at: 8.days.ago)
      create(:reporting_event, account: account, inbox: inbox, conversation: other,
                               name: 'conversation_bot_resolved', event_start_time: 6.days.ago, event_end_time: 6.days.ago)

      expect(described_class.new(assistant, '30').metrics[:reopen_rate][:current]).to eq(50.0)
    end

    it 'ignores a reopen that landed after a completed window ended' do
      travel_to(Time.utc(2026, 7, 15)) do
        convo = create(:conversation, account: account, inbox: inbox)
        create(:message, account: account, inbox: inbox, conversation: convo,
                         sender: assistant, message_type: :outgoing, private: false, created_at: Time.utc(2026, 6, 10))
        create(:reporting_event, account: account, inbox: inbox, conversation: convo,
                                 name: 'conversation_bot_resolved', created_at: Time.utc(2026, 6, 12),
                                 event_start_time: Time.utc(2026, 6, 12), event_end_time: Time.utc(2026, 6, 12))
        # Reopened on July 1, after the June window closed; June's rate must not count it.
        create(:reporting_event, account: account, inbox: inbox, conversation: convo,
                                 name: 'conversation_opened', value: 120,
                                 event_start_time: Time.utc(2026, 6, 12), event_end_time: Time.utc(2026, 7, 1))

        expect(described_class.new(assistant, 'last_month').metrics[:reopen_rate][:current]).to eq(0.0)
      end
    end

    it 'derives the cohort from handled conversations, not current inbox membership' do
      create(:reporting_event, account: account, inbox: inbox, conversation: conversation,
                               name: 'conversation_captain_inference_resolved', event_start_time: 6.days.ago, event_end_time: 6.days.ago)
      create(:reporting_event, account: account, inbox: inbox, conversation: conversation,
                               name: 'conversation_opened', value: 120, event_start_time: 6.days.ago, event_end_time: 4.days.ago)
      # The assistant is later removed from the inbox; the cohort must still resolve via handled messages.
      CaptainInbox.where(captain_assistant: assistant).delete_all

      expect(described_class.new(assistant, '30').metrics[:reopen_rate][:current]).to eq(100.0)
    end
  end

  describe 'timezone anchoring' do
    # 2026-07-01 03:00 UTC is still 2026-06-30 in any timezone behind UTC by 4h+.
    it 'anchors the this_month window to the supplied offset, not UTC' do
      travel_to(Time.utc(2026, 7, 1, 3, 0, 0)) do
        utc = described_class.new(assistant, 'this_month').period
        la = described_class.new(assistant, 'this_month', -7).period

        expect(utc[:starts_on]).to eq(Date.new(2026, 7, 1))
        expect(la[:starts_on]).to eq(Date.new(2026, 6, 1))
        expect(la[:ends_on]).to eq(Date.new(2026, 6, 30))
      end
    end

    it 'defaults to UTC when no offset is given' do
      travel_to(Time.utc(2026, 7, 1, 3, 0, 0)) do
        expect(described_class.new(assistant, 'this_month').period[:starts_on]).to eq(Date.new(2026, 7, 1))
      end
    end
  end

  describe '#metrics knowledge' do
    before do
      create_list(:captain_assistant_response, 3, assistant: assistant, account: account, status: :approved)
      create(:captain_assistant_response, assistant: assistant, account: account, status: :pending)
      create_list(:captain_document, 2, assistant: assistant, account: account)
    end

    it 'returns approved, pending, document counts and coverage' do
      knowledge = described_class.new(assistant, '30').metrics[:knowledge]

      expect(knowledge).to eq(approved: 3, pending: 1, documents: 2, coverage: 75)
    end

    it 'reports zero coverage when there are no responses' do
      Captain::AssistantResponse.where(assistant: assistant).delete_all

      knowledge = described_class.new(assistant, '30').metrics[:knowledge]

      expect(knowledge[:coverage]).to eq(0)
    end
  end

  describe '#period' do
    it 'labels a day range and exposes its bounds' do
      period = described_class.new(assistant, '30').period

      expect(period[:label]).to eq('the last 30 days')
      expect(period[:starts_on]).to eq(30.days.ago.to_date)
      expect(period[:ends_on]).to eq(Time.zone.today)
    end

    it 'labels the this_month range' do
      expect(described_class.new(assistant, 'this_month').period[:label]).to eq('this month')
    end

    it 'labels the last_month range' do
      expect(described_class.new(assistant, 'last_month').period[:label]).to eq('last month')
    end
  end
end
