# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SnoozeTool, :aloo do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }

  before do
    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
  end

  after do
    Aloo::Current.reset
  end

  describe '.description' do
    it 'describes when to snooze' do
      expect(described_class.description).to include('Snooze')
      expect(described_class.description).to include('conversation')
    end
  end

  describe '#execute' do
    let(:tool) { described_class.new }

    context 'with relative time strings' do
      it 'parses "1 hour"' do
        result = tool.execute(until_time: '1 hour')

        expect(result[:success]).to be true
        expect(conversation.reload.status).to eq('snoozed')
        expect(conversation.snoozed_until).to be_within(1.minute).of(1.hour.from_now)
      end

      it 'parses "2 hours"' do
        result = tool.execute(until_time: '2 hours')

        expect(result[:success]).to be true
        expect(conversation.reload.snoozed_until).to be_within(1.minute).of(2.hours.from_now)
      end

      it 'parses "1 day"' do
        result = tool.execute(until_time: '1 day')

        expect(result[:success]).to be true
        expect(conversation.reload.snoozed_until).to be_within(1.minute).of(1.day.from_now)
      end

      it 'parses "3 days"' do
        result = tool.execute(until_time: '3 days')

        expect(result[:success]).to be true
        expect(conversation.reload.snoozed_until).to be_within(1.minute).of(3.days.from_now)
      end

      it 'parses "30 minutes"' do
        result = tool.execute(until_time: '30 minutes')

        expect(result[:success]).to be true
        expect(conversation.reload.snoozed_until).to be_within(1.minute).of(30.minutes.from_now)
      end

      it 'parses "1 week"' do
        result = tool.execute(until_time: '1 week')

        expect(result[:success]).to be true
        expect(conversation.reload.snoozed_until).to be_within(1.minute).of(1.week.from_now)
      end

      it 'parses "tomorrow" (case insensitive)' do
        result = tool.execute(until_time: 'Tomorrow')

        expect(result[:success]).to be true
        expected_time = 1.day.from_now.beginning_of_day + 9.hours
        expect(conversation.reload.snoozed_until).to be_within(1.minute).of(expected_time)
      end

      it 'parses "next week"' do
        result = tool.execute(until_time: 'next week')

        expect(result[:success]).to be true
        expected_time = 1.week.from_now.beginning_of_day + 9.hours
        expect(conversation.reload.snoozed_until).to be_within(1.minute).of(expected_time)
      end
    end

    context 'with ISO8601 datetime' do
      it 'parses ISO8601 format' do
        future_time = 2.days.from_now
        result = tool.execute(until_time: future_time.iso8601)

        expect(result[:success]).to be true
        expect(conversation.reload.snoozed_until).to be_within(1.second).of(future_time)
      end
    end

    context 'with Unix timestamp' do
      it 'parses Unix timestamp in seconds' do
        future_time = 2.days.from_now
        result = tool.execute(until_time: future_time.to_i.to_s)

        expect(result[:success]).to be true
        expect(conversation.reload.snoozed_until).to be_within(1.second).of(future_time)
      end

      it 'parses Unix timestamp in milliseconds' do
        future_time = 2.days.from_now
        timestamp_ms = (future_time.to_f * 1000).to_i.to_s
        result = tool.execute(until_time: timestamp_ms)

        expect(result[:success]).to be true
        expect(conversation.reload.snoozed_until).to be_within(1.second).of(future_time)
      end
    end

    context 'with invalid time' do
      it 'returns error for unparseable time' do
        result = tool.execute(until_time: 'invalid time format')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Could not parse')
      end

      it 'returns error for past time' do
        past_time = 1.hour.ago
        result = tool.execute(until_time: past_time.iso8601)

        expect(result[:success]).to be false
        expect(result[:error]).to include('future')
      end

      it 'returns error for empty time' do
        result = tool.execute(until_time: '')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Could not parse')
      end
    end

    context 'when already snoozed' do
      before do
        conversation.update!(status: :snoozed, snoozed_until: 1.day.from_now)
      end

      it 'returns error response' do
        result = tool.execute(until_time: '2 hours')

        expect(result[:success]).to be false
        expect(result[:error]).to include('already snoozed')
      end
    end

    context 'with reason' do
      it 'adds reason as private note' do
        expect do
          tool.execute(until_time: '1 hour', reason: 'Waiting for customer to check order')
        end.to change { conversation.messages.where(private: true).count }.by(1)

        note = conversation.messages.where(private: true).last
        expect(note.content).to include('Waiting for customer to check order')
      end

      it 'includes snooze time in note' do
        tool.execute(until_time: '1 hour', reason: 'Test reason')

        note = conversation.messages.where(private: true).last
        expect(note.content).to include('Snoozed until')
      end
    end

    context 'tracking execution' do
      it 'tracks in conversation context' do
        tool.execute(until_time: '1 hour')

        context = Aloo::ConversationContext.find_by(conversation: conversation)
        expect(context.tool_history).not_to be_empty
        expect(context.tool_history.last['tool']).to eq('snooze')
      end

      it 'logs execution' do
        expect_any_instance_of(described_class).to receive(:log_execution)
          .with(hash_including(until_time: '1 hour'), anything)

        tool.execute(until_time: '1 hour')
      end
    end

    context 'response format' do
      it 'includes human readable time' do
        result = tool.execute(until_time: '1 hour')

        expect(result[:data][:human_readable]).to be_present
      end

      it 'includes ISO8601 snoozed_until' do
        result = tool.execute(until_time: '1 hour')

        expect(result[:data][:snoozed_until]).to match(/\d{4}-\d{2}-\d{2}T/)
      end

      it 'includes success message' do
        result = tool.execute(until_time: '1 hour')

        expect(result[:data][:message]).to include('snoozed until')
      end
    end

    context 'when error occurs' do
      before do
        allow(conversation).to receive(:update!).and_raise(StandardError, 'DB error')
      end

      it 'returns error response' do
        result = tool.execute(until_time: '1 hour')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to snooze conversation')
      end
    end

    context 'without required context' do
      before do
        Aloo::Current.conversation = nil
      end

      it 'returns error response' do
        result = tool.execute(until_time: '1 hour')

        expect(result[:success]).to be false
        expect(result[:error]).to include('Conversation context required')
      end
    end
  end
end
