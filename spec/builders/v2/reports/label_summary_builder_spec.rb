require 'rails_helper'

RSpec.describe V2::Reports::LabelSummaryBuilder do
  include ActiveJob::TestHelper

  let_it_be(:account) { create(:account) }
  let_it_be(:label_1) { create(:label, title: 'label_1', account: account) }
  let_it_be(:label_2) { create(:label, title: 'label_2', account: account) }
  let_it_be(:label_3) { create(:label, title: 'label_3', account: account) }

  let(:params) do
    {
      business_hours: business_hours,
      since: (Time.zone.today - 3.days).to_time.to_i.to_s,
      until: Time.zone.today.end_of_day.to_time.to_i.to_s,
      timezone_offset: 0
    }
  end
  let(:builder) { described_class.new(account: account, params: params) }

  describe '#initialize' do
    let(:business_hours) { false }

    it 'sets account and params' do
      expect(builder.account).to eq(account)
      expect(builder.params).to eq(params)
    end

    it 'sets timezone from timezone_offset' do
      builder_with_offset = described_class.new(account: account, params: { timezone_offset: -8 })
      expect(builder_with_offset.instance_variable_get(:@timezone)).to eq('Pacific Time (US & Canada)')
    end

    it 'defaults timezone when timezone_offset is not provided' do
      builder_without_offset = described_class.new(account: account, params: {})
      expect(builder_without_offset.instance_variable_get(:@timezone)).not_to be_nil
    end
  end

  describe '#build' do
    context 'when there are no labels' do
      let(:business_hours) { false }
      let(:empty_account) { create(:account) }
      let(:empty_builder) { described_class.new(account: empty_account, params: params) }

      it 'returns empty array' do
        expect(empty_builder.build).to eq([])
      end
    end

    context 'when there are labels but no conversations' do
      let(:business_hours) { false }

      it 'returns zero values for all labels' do
        report = builder.build

        expect(report.length).to eq(3)

        bug_report = report.find { |r| r[:name] == 'label_1' }
        feature_request = report.find { |r| r[:name] == 'label_2' }
        customer_support = report.find { |r| r[:name] == 'label_3' }

        [
          [bug_report, label_1, 'label_1'],
          [feature_request, label_2, 'label_2'],
          [customer_support, label_3, 'label_3']
        ].each do |report_data, label, label_name|
          expect(report_data).to include(
            id: label.id,
            name: label_name,
            conversations_count: 0,
            avg_resolution_time: 0,
            avg_first_response_time: 0,
            avg_reply_time: 0,
            resolved_conversations_count: 0
          )
        end
      end
    end

    context 'when there are labeled conversations with metrics' do
      before do
        travel_to(Time.zone.today) do
          user = create(:user, account: account)
          inbox = create(:inbox, account: account)
          create(:inbox_member, user: user, inbox: inbox)

          gravatar_url = 'https://www.gravatar.com'
          stub_request(:get, /#{gravatar_url}.*/).to_return(status: 404)

          perform_enqueued_jobs do
            # Create conversations with label_1
            3.times do
              conversation = create(:conversation, account: account,
                                                   inbox: inbox, assignee: user,
                                                   created_at: Time.zone.today)
              create_list(:message, 2, message_type: 'outgoing',
                                       account: account, inbox: inbox,
                                       conversation: conversation,
                                       created_at: Time.zone.today + 1.hour)
              create_list(:message, 1, message_type: 'incoming',
                                       account: account, inbox: inbox,
                                       conversation: conversation,
                                       created_at: Time.zone.today + 2.hours)
              conversation.update_labels('label_1')
              conversation.label_list
              conversation.save!
            end

            # Create conversations with label_2
            2.times do
              conversation = create(:conversation, account: account,
                                                   inbox: inbox, assignee: user,
                                                   created_at: Time.zone.today)
              create_list(:message, 1, message_type: 'outgoing',
                                       account: account, inbox: inbox,
                                       conversation: conversation,
                                       created_at: Time.zone.today + 1.hour)
              conversation.update_labels('label_2')
              conversation.label_list
              conversation.save!
            end

            # Resolve some conversations
            conversations_to_resolve = account.conversations.first(2)
            conversations_to_resolve.each(&:toggle_status)

            # Create some reporting events
            account.conversations.reload.each_with_index do |conv, idx|
              # First response times
              create(:reporting_event,
                     account: account,
                     conversation: conv,
                     name: 'first_response',
                     value: (30 + (idx * 10)) * 60,
                     value_in_business_hours: (20 + (idx * 5)) * 60,
                     created_at: Time.zone.today)

              # Reply times
              create(:reporting_event,
                     account: account,
                     conversation: conv,
                     name: 'reply_time',
                     value: (15 + (idx * 5)) * 60,
                     value_in_business_hours: (10 + (idx * 3)) * 60,
                     created_at: Time.zone.today)

              # Resolution times for resolved conversations
              next unless conv.resolved?

              create(:reporting_event,
                     account: account,
                     conversation: conv,
                     name: 'conversation_resolved',
                     value: (60 + (idx * 30)) * 60,
                     value_in_business_hours: (45 + (idx * 20)) * 60,
                     created_at: Time.zone.today)
            end
          end
        end
      end

      context 'when business hours is disabled' do
        let(:business_hours) { false }

        it 'returns correct label stats using regular values' do
          report = builder.build

          expect(report.length).to eq(3)

          label_1_report = report.find { |r| r[:name] == 'label_1' }
          label_2_report = report.find { |r| r[:name] == 'label_2' }
          label_3_report = report.find { |r| r[:name] == 'label_3' }

          expect(label_1_report).to include(
            conversations_count: 3,
            avg_first_response_time: be > 0,
            avg_reply_time: be > 0
          )

          expect(label_2_report).to include(
            conversations_count: 2,
            avg_first_response_time: be > 0,
            avg_reply_time: be > 0
          )

          expect(label_3_report).to include(
            conversations_count: 0,
            avg_first_response_time: 0,
            avg_reply_time: 0
          )
        end
      end

      context 'when business hours is enabled' do
        let(:business_hours) { true }

        it 'returns correct label stats using business hours values' do
          report = builder.build

          expect(report.length).to eq(3)

          label_1_report = report.find { |r| r[:name] == 'label_1' }
          label_2_report = report.find { |r| r[:name] == 'label_2' }

          expect(label_1_report[:conversations_count]).to eq(3)
          expect(label_1_report[:avg_first_response_time]).to be > 0
          expect(label_1_report[:avg_reply_time]).to be > 0

          expect(label_2_report[:conversations_count]).to eq(2)
          expect(label_2_report[:avg_first_response_time]).to be > 0
          expect(label_2_report[:avg_reply_time]).to be > 0
        end
      end
    end

    context 'when filtering by date range' do
      let(:business_hours) { false }

      before do
        travel_to(Time.zone.today) do
          user = create(:user, account: account)
          inbox = create(:inbox, account: account)
          create(:inbox_member, user: user, inbox: inbox)

          gravatar_url = 'https://www.gravatar.com'
          stub_request(:get, /#{gravatar_url}.*/).to_return(status: 404)

          perform_enqueued_jobs do
            # Conversation within range
            conversation_in_range = create(:conversation, account: account,
                                                          inbox: inbox, assignee: user,
                                                          created_at: 2.days.ago)
            conversation_in_range.update_labels('label_1')
            conversation_in_range.label_list
            conversation_in_range.save!

            create(:reporting_event,
                   account: account,
                   conversation: conversation_in_range,
                   name: 'first_response',
                   value: 1800,
                   created_at: 2.days.ago)

            # Conversation outside range (too old)
            conversation_out_of_range = create(:conversation, account: account,
                                                              inbox: inbox, assignee: user,
                                                              created_at: 1.week.ago)
            conversation_out_of_range.update_labels('label_1')
            conversation_out_of_range.label_list
            conversation_out_of_range.save!

            create(:reporting_event,
                   account: account,
                   conversation: conversation_out_of_range,
                   name: 'first_response',
                   value: 3600,
                   created_at: 1.week.ago)
          end
        end
      end

      it 'only includes conversations within the date range' do
        report = builder.build

        expect(report.length).to eq(3)

        label_1_report = report.find { |r| r[:name] == 'label_1' }
        expect(label_1_report).not_to be_nil
        expect(label_1_report[:conversations_count]).to eq(1)
        expect(label_1_report[:avg_first_response_time]).to eq(1800.0)
      end
    end

    context 'with business hours parameter' do
      let(:business_hours) { 'true' }

      before do
        travel_to(Time.zone.today) do
          user = create(:user, account: account)
          inbox = create(:inbox, account: account)
          create(:inbox_member, user: user, inbox: inbox)

          gravatar_url = 'https://www.gravatar.com'
          stub_request(:get, /#{gravatar_url}.*/).to_return(status: 404)

          perform_enqueued_jobs do
            conversation = create(:conversation, account: account,
                                                 inbox: inbox, assignee: user,
                                                 created_at: Time.zone.today)
            conversation.update_labels('label_1')
            conversation.label_list
            conversation.save!

            create(:reporting_event,
                   account: account,
                   conversation: conversation,
                   name: 'first_response',
                   value: 3600,
                   value_in_business_hours: 1800,
                   created_at: Time.zone.today)
          end
        end
      end

      it 'properly casts string "true" to boolean and uses business hours values' do
        report = builder.build

        expect(report.length).to eq(3)

        label_1_report = report.find { |r| r[:name] == 'label_1' }
        expect(label_1_report).not_to be_nil
        expect(label_1_report[:avg_first_response_time]).to eq(1800.0)
      end
    end

    context 'with resolution count with multiple resolutions of same conversation' do
      let(:business_hours) { false }
      let(:account2) { create(:account) }
      let(:unique_label_name) { SecureRandom.uuid }
      let(:test_label) { create(:label, title: unique_label_name, account: account2) }
      let(:test_date) { Date.new(2025, 6, 15) }
      let(:account2_builder) do
        described_class.new(account: account2, params: {
                              business_hours: false,
                              since: test_date.to_time.to_i.to_s,
                              until: test_date.end_of_day.to_time.to_i.to_s,
                              timezone_offset: 0
                            })
      end

      before do
        # Ensure test_label is created
        test_label

        travel_to(test_date) do
          user = create(:user, account: account2)
          inbox = create(:inbox, account: account2)
          create(:inbox_member, user: user, inbox: inbox)

          gravatar_url = 'https://www.gravatar.com'
          stub_request(:get, /#{gravatar_url}.*/).to_return(status: 404)

          perform_enqueued_jobs do
            conversation = create(:conversation, account: account2,
                                                 inbox: inbox, assignee: user,
                                                 created_at: test_date)
            conversation.update_labels(unique_label_name)
            conversation.label_list
            conversation.save!

            # First resolution
            conversation.resolved!

            # Reopen conversation
            conversation.open!

            # Second resolution
            conversation.resolved!
          end
        end
      end

      it 'counts multiple resolution events for same conversation' do
        report = account2_builder.build

        test_label_report = report.find { |r| r[:name] == unique_label_name }
        expect(test_label_report).not_to be_nil
        expect(test_label_report[:resolved_conversations_count]).to eq(2)
      end
    end
  end
end
