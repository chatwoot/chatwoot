require 'rails_helper'

RSpec.describe V2::Reports::DrilldownBuilder do
  subject(:drilldown) { described_class.new(account, params).build }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:current_time) { Time.zone.parse('2026-05-20 12:00') }
  let(:bucket_start) { current_time.beginning_of_day }
  let(:bucket_end) { bucket_start + 1.day }
  let(:metric) { 'conversations_count' }
  let(:params) do
    {
      metric: metric,
      type: filter_type,
      id: filter_id,
      since: bucket_start.to_i.to_s,
      until: bucket_end.to_i.to_s,
      bucket_timestamp: bucket_start.to_i.to_s,
      group_by: 'day',
      timezone_offset: '0',
      business_hours: false
    }
  end
  let(:filter_type) { :account }
  let(:filter_id) { nil }

  before do
    travel_to current_time
  end

  describe '#build' do
    context 'with conversation count metric' do
      it 'returns conversations created in the clicked bucket' do
        conversation = create(
          :conversation,
          account: account,
          inbox: inbox,
          created_at: bucket_start + 2.hours,
          last_activity_at: bucket_start + 4.hours
        )
        last_message = create(
          :message,
          account: account,
          inbox: inbox,
          conversation: conversation,
          message_type: :incoming,
          content: 'Latest customer note',
          created_at: bucket_start + 3.hours
        )
        conversation.update!(last_activity_at: bucket_start + 4.hours)
        create(:conversation, account: account, inbox: inbox, created_at: bucket_start - 1.hour)

        expect(drilldown[:meta]).to include(metric: 'conversations_count', record_type: 'conversation', total_count: 1)
        expect(drilldown[:meta][:bucket]).to eq({ since: bucket_start.to_i, until: bucket_end.to_i })
        expect(drilldown[:payload].first[:conversation][:display_id]).to eq(conversation.display_id)
        expect(drilldown[:payload].first[:conversation][:created_at]).to eq(
          (bucket_start + 2.hours).to_i
        )
        expect(drilldown[:payload].first[:conversation][:last_activity_at]).to eq(
          (bucket_start + 4.hours).to_i
        )
        expect(drilldown[:payload].first[:conversation][:last_message][:id]).to eq(last_message.id)
        expect(drilldown[:payload].first[:conversation][:last_message][:content]).to eq('Latest customer note')
      end

      it 'loads latest messages in one query for the page conversations' do
        first_conversation = create(:conversation, account: account, inbox: inbox, created_at: bucket_start + 2.hours)
        second_conversation = create(:conversation, account: account, inbox: inbox, created_at: bucket_start + 3.hours)
        first_message = create(:message, account: account, inbox: inbox, conversation: first_conversation, created_at: bucket_start + 4.hours)
        second_message = create(:message, account: account, inbox: inbox, conversation: second_conversation, created_at: bucket_start + 5.hours)

        message_queries = []
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _started, _finished, _unique_id, payload|
          message_queries << payload[:sql] if payload[:sql].match?(/\ASELECT .*FROM "messages"/m) && !payload[:cached]
        end

        payload = drilldown[:payload]

        expect(payload.map { |row| row[:conversation][:last_message][:id] }).to contain_exactly(
          first_message.id,
          second_message.id
        )
        expect(message_queries.size).to eq(1)
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end

      context 'when filtering by agent' do
        let(:metric) { 'conversations_count' }
        let(:filter_type) { :agent }
        let(:filter_id) { agent.id }
        let(:agent) { create(:user, account: account) }
        let(:other_agent) { create(:user, account: account) }

        it 'returns only conversations assigned to the selected agent' do
          conversation = create(:conversation, account: account, inbox: inbox, assignee: agent, created_at: bucket_start + 2.hours)
          create(:conversation, account: account, inbox: inbox, assignee: other_agent, created_at: bucket_start + 3.hours)

          expect(drilldown[:meta][:total_count]).to eq(1)
          expect(drilldown[:payload].first[:conversation][:id]).to eq(conversation.id)
        end
      end
    end

    context 'with message count metric' do
      let(:metric) { 'incoming_messages_count' }

      it 'returns messages created in the clicked bucket' do
        conversation = create(:conversation, account: account, inbox: inbox)
        message = create(:message, account: account, inbox: inbox, conversation: conversation,
                                   message_type: :incoming, content: 'Need help', created_at: bucket_start + 1.hour)
        create(:message, account: account, inbox: inbox, conversation: conversation,
                         message_type: :outgoing, created_at: bucket_start + 2.hours)

        expect(drilldown[:meta]).to include(record_type: 'message', total_count: 1)
        expect(drilldown[:payload].first[:record_type]).to eq('message')
        expect(drilldown[:payload].first[:message][:id]).to eq(message.id)
        expect(drilldown[:payload].first[:message][:content]).to eq('Need help')
      end
    end

    context 'with first response time metric' do
      let(:metric) { 'avg_first_response_time' }
      let(:agent) { create(:user, account: account) }

      it 'infers the related outgoing message and uses the selected metric value' do
        conversation = create(:conversation, account: account, inbox: inbox)
        message = create(:message, account: account, inbox: inbox, conversation: conversation,
                                   sender: agent, message_type: :outgoing, created_at: bucket_start + 2.hours)
        create(:reporting_event, account: account, inbox: inbox, conversation: conversation, user: agent,
                                 name: 'first_response', value: 120, value_in_business_hours: 45,
                                 created_at: bucket_start + 2.hours, event_end_time: message.created_at)

        params[:business_hours] = true

        expect(drilldown[:meta]).to include(record_type: 'message', total_count: 1)
        expect(drilldown[:payload].first[:record_type]).to eq('message')
        expect(drilldown[:payload].first[:message][:id]).to eq(message.id)
        expect(drilldown[:payload].first[:metric_value]).to eq(45)
      end

      it 'loads inferred and latest messages in two queries for the page events' do
        first_conversation = create(:conversation, account: account, inbox: inbox)
        second_conversation = create(:conversation, account: account, inbox: inbox)
        first_message = create(:message, account: account, inbox: inbox, conversation: first_conversation,
                                         sender: agent, message_type: :outgoing, created_at: bucket_start + 2.hours)
        second_message = create(:message, account: account, inbox: inbox, conversation: second_conversation,
                                          sender: agent, message_type: :outgoing, created_at: bucket_start + 3.hours)
        create(:reporting_event, account: account, inbox: inbox, conversation: first_conversation, user: agent,
                                 name: 'first_response', value: 120, created_at: bucket_start + 2.hours,
                                 event_end_time: first_message.created_at)
        create(:reporting_event, account: account, inbox: inbox, conversation: second_conversation, user: agent,
                                 name: 'first_response', value: 90, created_at: bucket_start + 3.hours,
                                 event_end_time: second_message.created_at)

        message_queries = []
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _started, _finished, _unique_id, payload|
          message_queries << payload[:sql] if payload[:sql].match?(/\ASELECT .*FROM "messages"/m) && !payload[:cached]
        end

        payload = drilldown[:payload]

        expect(payload.map { |row| row[:message][:id] }).to contain_exactly(
          first_message.id,
          second_message.id
        )
        expect(message_queries.size).to eq(2)
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end

      it 'falls back to the conversation when no matching message is found' do
        conversation = create(:conversation, account: account, inbox: inbox)
        create(:reporting_event, account: account, inbox: inbox, conversation: conversation, user: agent,
                                 name: 'first_response', value: 120, created_at: bucket_start + 2.hours,
                                 event_end_time: bucket_start + 2.hours)

        expect(drilldown[:payload].first[:record_type]).to eq('conversation')
        expect(drilldown[:payload].first[:conversation][:id]).to eq(conversation.id)
      end
    end

    context 'with bot handoff count metric' do
      let(:metric) { 'bot_handoffs_count' }

      it 'returns one row per handoff conversation' do
        first_conversation = create(:conversation, account: account, inbox: inbox)
        second_conversation = create(:conversation, account: account, inbox: inbox)

        create(:reporting_event, account: account, inbox: inbox, conversation: first_conversation,
                                 name: 'conversation_bot_handoff', created_at: bucket_start + 1.hour)
        create(:reporting_event, account: account, inbox: inbox, conversation: first_conversation,
                                 name: 'conversation_bot_handoff', created_at: bucket_start + 2.hours)
        create(:reporting_event, account: account, inbox: inbox, conversation: second_conversation,
                                 name: 'conversation_bot_handoff', created_at: bucket_start + 3.hours)

        expect(drilldown[:meta][:total_count]).to eq(2)
        expect(drilldown[:payload].map { |row| row[:conversation][:id] }).to contain_exactly(
          first_conversation.id,
          second_conversation.id
        )
        expect(drilldown[:payload].pluck(:event_name)).to all(eq('conversation_bot_handoff'))
      end
    end

    context 'with bot resolution count metric' do
      let(:metric) { 'bot_resolutions_count' }

      before do
        params[:until] = (bucket_start + 2.days).to_i.to_s
      end

      it 'excludes conversations with handoffs anywhere in the selected report range' do
        resolved_conversation = create(:conversation, account: account, inbox: inbox)
        handed_off_conversation = create(:conversation, account: account, inbox: inbox)

        create(:reporting_event, account: account, inbox: inbox, conversation: resolved_conversation,
                                 name: 'conversation_bot_resolved', created_at: bucket_start + 1.hour)
        create(:reporting_event, account: account, inbox: inbox, conversation: handed_off_conversation,
                                 name: 'conversation_bot_resolved', created_at: bucket_start + 2.hours)
        create(:reporting_event, account: account, inbox: inbox, conversation: handed_off_conversation,
                                 name: 'conversation_bot_handoff', created_at: bucket_start + 1.day)

        expect(drilldown[:meta][:total_count]).to eq(1)
        expect(drilldown[:payload].first[:conversation][:id]).to eq(resolved_conversation.id)
      end
    end
  end
end
