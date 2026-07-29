require 'rails_helper'

RSpec.describe Captain::AssistantStatsBuilder do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }

  before { create(:captain_inbox, captain_assistant: assistant, inbox: inbox) }

  def create_outcome(created_at:, **attributes)
    conversation = create(:conversation, account: account, inbox: inbox)
    create(
      :captain_conversation_outcome,
      account: account,
      assistant: assistant,
      conversation: conversation,
      inbox: inbox,
      created_at: created_at,
      **attributes
    )
  end

  describe '#metrics' do
    # Two conversations handled in the current 30-day window, one in the previous.
    # convo_a resolved autonomously; convo_b was handed off.
    let!(:current_outcome_a) do
      create_outcome(created_at: 5.days.ago, first_captain_reply_at: 5.days.ago, resolved_at: 4.days.ago)
    end
    let!(:current_outcome_b) do
      create_outcome(
        created_at: 5.days.ago,
        first_captain_reply_at: 5.days.ago,
        handoff_at: 5.days.ago,
        handoff_reason_category: 'missing_knowledge'
      )
    end

    before do
      create_outcome(created_at: 45.days.ago, first_captain_reply_at: 45.days.ago)

      [current_outcome_a, current_outcome_b].each do |outcome|
        create(:message, account: account, inbox: inbox, conversation: outcome.conversation,
                         sender: assistant, message_type: :outgoing, private: false, created_at: 5.days.ago)
      end
    end

    it 'returns every metric for the current and previous window' do
      metrics = described_class.new(assistant, '30').metrics

      expect(metrics.keys).to contain_exactly(
        :conversations_handled, :auto_resolution_rate, :handoff_rate,
        :hours_saved, :reopen_rate, :conversation_depth
      )
      expect(metrics[:conversations_handled]).to include(:current, :previous, :trend)
    end

    it 'counts involved conversations per window and the percent trend' do
      handled = described_class.new(assistant, '30').metrics[:conversations_handled]

      expect(handled[:current]).to eq(2)
      expect(handled[:previous]).to eq(1)
      expect(handled[:trend]).to eq(100.0)
    end

    it 'derives auto-resolution and handoff rates from the outcome rows' do
      metrics = described_class.new(assistant, '30').metrics

      expect(metrics[:auto_resolution_rate][:current]).to eq(50.0)
      expect(metrics[:handoff_rate][:current]).to eq(50.0)
    end

    it 'does not count untouched or usage-limit-blocked demand as handled' do
      create_outcome(created_at: 4.days.ago)
      create_outcome(created_at: 4.days.ago, handoff_at: 4.days.ago, handoff_reason_category: 'usage_limit')

      expect(described_class.new(assistant, '30').metrics[:conversations_handled][:current]).to eq(2)
    end

    it 'does not count a resolution as autonomous when a human replied before it' do
      current_outcome_a.update!(first_human_reply_at: 5.days.ago)

      expect(described_class.new(assistant, '30').metrics[:auto_resolution_rate][:current]).to eq(0.0)
    end

    it 'excludes demand that entered outside the current window' do
      expect(described_class.new(assistant, '7').metrics[:conversations_handled][:current]).to eq(2)
      expect(described_class.new(assistant, '7').metrics[:conversations_handled][:previous]).to eq(0)
    end

    it 'computes conversation depth as public replies per handled conversation' do
      depth = described_class.new(assistant, '30').metrics[:conversation_depth]

      # 2 public outgoing replies across 2 distinct conversations in the current window.
      expect(depth[:current]).to eq(1.0)
    end

    it 'ignores private notes and incoming messages when counting public replies' do
      create(:message, account: account, inbox: inbox, conversation: current_outcome_a.conversation,
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
      expect(described_class.new(assistant, '365000').range).to eq('7')
      expect(described_class.new(assistant, 'bogus').range).to eq('7')
      expect(described_class.new(assistant, nil).range).to eq('7')
    end
  end

  describe '#metrics reopen_rate' do
    it 'counts autonomously resolved conversations that reopened afterwards' do
      create_outcome(
        created_at: 8.days.ago,
        first_captain_reply_at: 8.days.ago,
        resolved_at: 6.days.ago,
        last_reopened_at: 4.days.ago,
        reopen_count: 1
      )
      create_outcome(created_at: 8.days.ago, first_captain_reply_at: 8.days.ago, resolved_at: 6.days.ago)

      expect(described_class.new(assistant, '30').metrics[:reopen_rate][:current]).to eq(50.0)
    end

    it 'scopes the denominator to autonomous resolutions' do
      # Handed off then resolved: assisted, so it joins neither side of the rate.
      create_outcome(
        created_at: 8.days.ago,
        first_captain_reply_at: 8.days.ago,
        handoff_at: 7.days.ago,
        handoff_reason_category: 'customer_request',
        resolved_at: 6.days.ago,
        last_reopened_at: 4.days.ago,
        reopen_count: 1
      )

      expect(described_class.new(assistant, '30').metrics[:reopen_rate][:current]).to eq(0)
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

  describe '#faq_stats' do
    before do
      create_list(:captain_assistant_response, 3, assistant: assistant, account: account, status: :approved)
      assistant.faq_suggestions.create!(
        question: 'How do I enable the feature?',
        answer: 'Turn it on in settings.'
      )
      create_list(:captain_document, 2, assistant: assistant, account: account)
    end

    it 'returns approved FAQ, open suggestion, document counts and coverage' do
      stats = described_class.new(assistant).faq_stats

      expect(stats).to eq(approved: 3, suggestions: 1, documents: 2, coverage: 75)
    end

    it 'reports zero coverage when there are no FAQs or suggestions' do
      Captain::AssistantResponse.where(assistant: assistant).delete_all
      Captain::FaqSuggestion.where(assistant: assistant).delete_all

      stats = described_class.new(assistant).faq_stats

      expect(stats).to eq(approved: 0, suggestions: 0, documents: 2, coverage: 0)
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
