require 'rails_helper'

describe V2::ReportBuilder do
  include ActiveJob::TestHelper
  let_it_be(:account) { create(:account) }
  let_it_be(:label_1) { create(:label, title: 'Label_1', account: account) }
  let_it_be(:label_2) { create(:label, title: 'Label_2', account: account) }

  describe '#timeseries' do
    before do
      travel_to(Time.zone.today) do
        user = create(:user, account: account)
        inbox = create(:inbox, account: account)
        create(:inbox_member, user: user, inbox: inbox)

        gravatar_url = 'https://www.gravatar.com'
        stub_request(:get, /#{gravatar_url}.*/).to_return(status: 404)

        perform_enqueued_jobs do
          10.times do
            conversation = create(:conversation, account: account,
                                                 inbox: inbox, assignee: user,
                                                 created_at: Time.zone.today)
            create_list(:message, 5, message_type: 'outgoing',
                                     account: account, inbox: inbox,
                                     conversation: conversation, created_at: Time.zone.today + 2.hours)
            create_list(:message, 2, message_type: 'incoming',
                                     account: account, inbox: inbox,
                                     conversation: conversation,
                                     created_at: Time.zone.today + 3.hours)
            conversation.update_labels('label_1')
            conversation.label_list
            conversation.save!
          end

          5.times do
            conversation = create(:conversation, account: account,
                                                 inbox: inbox, assignee: user,
                                                 created_at: (Time.zone.today - 2.days))
            create_list(:message, 3, message_type: 'outgoing',
                                     account: account, inbox: inbox,
                                     conversation: conversation,
                                     created_at: (Time.zone.today - 2.days))
            create_list(:message, 1, message_type: 'incoming',
                                     account: account, inbox: inbox,
                                     conversation: conversation,
                                     created_at: (Time.zone.today - 2.days))
            conversation.update_labels('label_2')
            conversation.label_list
            conversation.save!
          end
        end
      end
    end

    context 'when report type is account' do
      it 'return conversations count' do
        params = {
          metric: 'conversations_count',
          type: :account,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s
        }

        builder = described_class.new(account, params)
        metrics = builder.timeseries

        expect(metrics[Time.zone.today]).to be 10
        expect(metrics[Time.zone.today - 2.days]).to be 5
      end

      it 'return incoming messages count' do
        params = {
          metric: 'incoming_messages_count',
          type: :account,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s
        }

        builder = described_class.new(account, params)
        metrics = builder.timeseries

        expect(metrics[Time.zone.today]).to be 20
        expect(metrics[Time.zone.today - 2.days]).to be 5
      end

      it 'return outgoing messages count' do
        params = {
          metric: 'outgoing_messages_count',
          type: :account,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s
        }

        builder = described_class.new(account, params)
        metrics = builder.timeseries

        expect(metrics[Time.zone.today]).to be 50
        expect(metrics[Time.zone.today - 2.days]).to be 15
      end

      it 'return resolutions count' do
        travel_to(Time.zone.today) do
          params = {
            metric: 'resolutions_count',
            type: :account,
            since: (Time.zone.today - 3.days).to_time.to_i.to_s,
            until: Time.zone.today.end_of_day.to_time.to_i.to_s
          }

          conversations = account.conversations.where('created_at < ?', 1.day.ago)
          perform_enqueued_jobs do
            # Resolve all 5 conversations
            conversations.each(&:resolved!)

            # Reopen 1 conversation
            conversations.first.open!
          end

          builder = described_class.new(account, params)
          metrics = builder.timeseries

          # 4 conversations are resolved
          expect(metrics[Time.zone.today]).to be 4
          expect(metrics[Time.zone.today - 2.days]).to be 0
        end
      end

      it 'returns bot_resolutions count' do
        travel_to(Time.zone.today) do
          params = {
            metric: 'bot_resolutions_count',
            type: :account,
            since: (Time.zone.today - 3.days).to_time.to_i.to_s,
            until: Time.zone.today.end_of_day.to_time.to_i.to_s
          }

          create(:agent_bot_inbox, inbox: account.inboxes.first)
          conversations = account.conversations.where('created_at < ?', 1.day.ago)
          conversations.each do |conversation|
            conversation.messages.outgoing.all.update(sender: nil)
          end

          perform_enqueued_jobs do
            # Resolve all 5 conversations
            conversations.each(&:resolved!)

            # Reopen 1 conversation
            conversations.first.open!
          end

          builder = described_class.new(account, params)
          metrics = builder.timeseries
          summary = builder.bot_summary

          # 4 conversations are resolved
          expect(metrics[Time.zone.today]).to be 4
          expect(metrics[Time.zone.today - 2.days]).to be 0
          expect(summary[:bot_resolutions_count]).to be 4
        end
      end

      it 'return bot_handoff count' do
        travel_to(Time.zone.today) do
          params = {
            metric: 'bot_handoffs_count',
            type: :account,
            since: (Time.zone.today - 3.days).to_time.to_i.to_s,
            until: Time.zone.today.end_of_day.to_time.to_i.to_s
          }

          create(:agent_bot_inbox, inbox: account.inboxes.first)
          conversations = account.conversations.where('created_at < ?', 1.day.ago)
          conversations.each do |conversation|
            conversation.pending!
            conversation.messages.outgoing.all.update(sender: nil)
          end

          perform_enqueued_jobs do
            # Resolve all 5 conversations
            conversations.each(&:bot_handoff!)

            # Reopen 1 conversation
            conversations.first.open!
          end

          builder = described_class.new(account, params)
          metrics = builder.timeseries
          summary = builder.bot_summary

          # 4 conversations are resolved
          expect(metrics[Time.zone.today]).to be 5
          expect(metrics[Time.zone.today - 2.days]).to be 0
          expect(summary[:bot_handoffs_count]).to be 5
        end
      end

      it 'returns average first response time' do
        params = {
          metric: 'avg_first_response_time',
          type: :account,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s
        }

        builder = described_class.new(account, params)
        metrics = builder.timeseries

        expect(metrics[Time.zone.today].to_f).to be 0.48e4
      end

      it 'returns summary' do
        params = {
          type: :account,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s
        }

        builder = described_class.new(account, params)
        metrics = builder.summary

        expect(metrics[:conversations_count]).to be 15
        expect(metrics[:incoming_messages_count]).to be 25
        expect(metrics[:outgoing_messages_count]).to be 65
        expect(metrics[:avg_resolution_time]).to be 0
        expect(metrics[:resolutions_count]).to be 0
      end

      it 'returns argument error for incorrect group by' do
        params = {
          type: :account,
          metric: 'avg_first_response_time',
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s,
          group_by: 'test'.to_s
        }

        builder = described_class.new(account, params)
        expect { builder.timeseries }.to raise_error(ArgumentError)
      end

      it 'logs error when metric is nil' do
        params = {
          metric: nil, # Set metric to nil to test this case
          type: :account,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s
        }

        builder = described_class.new(account, params)

        expect(Rails.logger).to receive(:error).with('ReportBuilder: Invalid metric - ')
        builder.timeseries
      end

      it 'calls the appropriate metric method for a valid metric' do
        params = {
          metric: 'not_conversation_count', # Provide a invalid metric
          type: :account,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s
        }

        builder = described_class.new(account, params)
        expect(Rails.logger).to receive(:error).with('ReportBuilder: Invalid metric - not_conversation_count')

        builder.timeseries
      end
    end

    context 'when report type is label' do
      it 'return conversations count' do
        params = {
          metric: 'conversations_count',
          type: :label,
          id: label_2.id,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s
        }

        builder = described_class.new(account, params)
        metrics = builder.timeseries

        expect(metrics[Time.zone.today - 2.days]).to be 5
      end

      it 'return incoming messages count' do
        params = {
          metric: 'incoming_messages_count',
          type: :label,
          id: label_1.id,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: (Time.zone.today + 1.day).to_time.to_i.to_s
        }

        builder = described_class.new(account, params)
        metrics = builder.timeseries

        expect(metrics[Time.zone.today]).to be 20
        expect(metrics[Time.zone.today - 2.days]).to be 0
      end

      it 'return outgoing messages count' do
        params = {
          metric: 'outgoing_messages_count',
          type: :label,
          id: label_1.id,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: (Time.zone.today + 1.day).to_time.to_i.to_s
        }

        builder = described_class.new(account, params)
        metrics = builder.timeseries

        expect(metrics[Time.zone.today]).to be 50
        expect(metrics[Time.zone.today - 2.days]).to be 0
      end

      it 'return resolutions count' do
        travel_to(Time.zone.today) do
          params = {
            metric: 'resolutions_count',
            type: :label,
            id: label_2.id,
            since: (Time.zone.today - 3.days).to_time.to_i.to_s,
            until: (Time.zone.today + 1.day).to_time.to_i.to_s
          }

          conversations = account.conversations.where('created_at < ?', 1.day.ago)

          perform_enqueued_jobs do
            # ensure 5 reporting events are created
            conversations.each(&:resolved!)

            # open one of the conversations to check if it is not counted
            conversations.last.open!
          end

          builder = described_class.new(account, params)
          metrics = builder.timeseries

          # this should count only 4 since the last conversation was reopened
          expect(metrics[Time.zone.today]).to be 4
          expect(metrics[Time.zone.today - 2.days]).to be 0
        end
      end

      it 'returns average first response time' do
        label_2.reporting_events.update(value: 1.5)

        params = {
          metric: 'avg_first_response_time',
          type: :label,
          id: label_2.id,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s
        }

        builder = described_class.new(account, params)
        metrics = builder.timeseries
        expect(metrics[Time.zone.today].to_f).to be 0.15e1
      end

      it 'returns summary' do
        params = {
          type: :label,
          id: label_2.id,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s
        }

        builder = described_class.new(account, params)
        metrics = builder.summary

        expect(metrics[:conversations_count]).to be 5
        expect(metrics[:incoming_messages_count]).to be 5
        expect(metrics[:outgoing_messages_count]).to be 15
        expect(metrics[:avg_resolution_time]).to be 0
        expect(metrics[:resolutions_count]).to be 0
      end

      it 'returns summary for correct group by' do
        params = {
          type: :label,
          id: label_2.id,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s,
          group_by: 'week'.to_s
        }

        builder = described_class.new(account, params)
        metrics = builder.summary

        expect(metrics[:conversations_count]).to be 5
        expect(metrics[:incoming_messages_count]).to be 5
        expect(metrics[:outgoing_messages_count]).to be 15
        expect(metrics[:avg_resolution_time]).to be 0
        expect(metrics[:resolutions_count]).to be 0
      end

      it 'returns argument error for incorrect group by' do
        params = {
          metric: 'avg_first_response_time',
          type: :label,
          id: label_2.id,
          since: (Time.zone.today - 3.days).to_time.to_i.to_s,
          until: Time.zone.today.end_of_day.to_time.to_i.to_s,
          group_by: 'test'.to_s
        }

        builder = described_class.new(account, params)
        expect { builder.timeseries }.to raise_error(ArgumentError)
      end
    end
  end
end
