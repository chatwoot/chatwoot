require 'rails_helper'

RSpec.describe Sla::EvaluateAppliedSlaService do
  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }

  let!(:sla_policy) do
    create(:sla_policy,
           account: account,
           first_response_time_threshold: nil,
           next_response_time_threshold: nil,
           resolution_time_threshold: nil)
  end
  let!(:conversation) do
    create(:conversation,
           created_at: 6.hours.ago, assignee: user_1,
           account: sla_policy.account,
           sla_policy: sla_policy)
  end
  let!(:applied_sla) { conversation.applied_sla }

  describe '#perform - SLA misses' do
    context 'when first response SLA is missed' do
      before { applied_sla.sla_policy.update(first_response_time_threshold: 1.hour) }

      it 'updates the SLA status to missed and logs a warning' do
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:warn).with("SLA frt missed for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
        expect(applied_sla.reload.sla_status).to eq('active_with_misses')
      end

      it 'creates SlaEvent only for frt miss' do
        described_class.new(applied_sla: applied_sla).perform

        expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'frt').count).to eq(1)
        expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'nrt').count).to eq(0)
        expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'rt').count).to eq(0)
      end
    end

    context 'when next response SLA is missed' do
      before do
        applied_sla.sla_policy.update(next_response_time_threshold: 1.hour)
        conversation.update(first_reply_created_at: 5.hours.ago, waiting_since: 5.hours.ago)
      end

      it 'updates the SLA status to missed and logs a warning' do
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:warn).with("SLA nrt missed for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
        expect(applied_sla.reload.sla_status).to eq('active_with_misses')
      end

      it 'creates SlaEvent only for nrt miss' do
        described_class.new(applied_sla: applied_sla).perform

        expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'frt').count).to eq(0)
        expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'nrt').count).to eq(1)
        expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'rt').count).to eq(0)
      end
    end

    context 'when resolution time SLA is missed' do
      before { applied_sla.sla_policy.update(resolution_time_threshold: 1.hour) }

      it 'updates the SLA status to missed and logs a warning' do
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:warn).with("SLA rt missed for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")

        expect(applied_sla.reload.sla_status).to eq('active_with_misses')
      end

      it 'creates SlaEvent only for rt miss' do
        described_class.new(applied_sla: applied_sla).perform

        expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'frt').count).to eq(0)
        expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'nrt').count).to eq(0)
        expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'rt').count).to eq(1)
      end
    end

    # We will mark resolved miss only if while processing the SLA
    # if the conversation is resolved and the resolution time is missed by small margins then we will not mark it as missed
    context 'when resolved conversation with resolution time SLA is missed' do
      before do
        conversation.resolved!
        applied_sla.sla_policy.update(resolution_time_threshold: 1.hour)
      end

      it 'does not update the SLA status to missed' do
        described_class.new(applied_sla: applied_sla).perform
        expect(applied_sla.reload.sla_status).to eq('hit')
      end
    end

    context 'when multiple SLAs are missed' do
      before do
        applied_sla.sla_policy.update(first_response_time_threshold: 1.hour, next_response_time_threshold: 1.hour, resolution_time_threshold: 1.hour)
        conversation.update(first_reply_created_at: 5.hours.ago, waiting_since: 5.hours.ago)
      end

      it 'updates the SLA status to missed and logs multiple warnings' do
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:warn).with("SLA rt missed for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}").exactly(1).time
        expect(Rails.logger).to have_received(:warn).with("SLA nrt missed for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}").exactly(1).time
        expect(applied_sla.reload.sla_status).to eq('active_with_misses')
      end
    end
  end

  describe '#perform - SLA hits' do
    context 'when first response SLA is hit' do
      before do
        applied_sla.sla_policy.update(first_response_time_threshold: 6.hours)
        conversation.update(first_reply_created_at: 30.minutes.ago)
      end

      it 'sla remains active until conversation is resolved' do
        described_class.new(applied_sla: applied_sla).perform
        expect(applied_sla.reload.sla_status).to eq('active')
      end

      it 'updates the SLA status to hit and logs an info when conversations is resolved' do
        conversation.resolved!
        allow(Rails.logger).to receive(:info)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:info).with("SLA hit for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
        expect(applied_sla.reload.sla_status).to eq('hit')
        expect(SlaEvent.count).to eq(0)
        expect(Notification.count).to eq(0)
      end
    end

    context 'when next response SLA is hit' do
      before do
        applied_sla.sla_policy.update(next_response_time_threshold: 6.hours)
        conversation.update(first_reply_created_at: 30.minutes.ago, waiting_since: nil)
      end

      it 'sla remains active until conversation is resolved' do
        described_class.new(applied_sla: applied_sla).perform
        expect(applied_sla.reload.sla_status).to eq('active')
      end

      it 'updates the SLA status to hit and logs an info when conversations is resolved' do
        conversation.resolved!
        allow(Rails.logger).to receive(:info)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:info).with("SLA hit for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
        expect(applied_sla.reload.sla_status).to eq('hit')
        expect(SlaEvent.count).to eq(0)
      end
    end

    context 'when resolution time SLA is hit' do
      before do
        applied_sla.sla_policy.update(resolution_time_threshold: 8.hours)
        conversation.resolved!
      end

      it 'updates the SLA status to hit and logs an info' do
        allow(Rails.logger).to receive(:info)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:info).with("SLA hit for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
        expect(applied_sla.reload.sla_status).to eq('hit')
        expect(SlaEvent.count).to eq(0)
      end
    end
  end

  describe 'SLA evaluation with frt hit, multiple nrt misses and rt miss' do
    before do
      # Setup SLA Policy thresholds
      applied_sla.sla_policy.update(
        first_response_time_threshold: 2.hours, # Hit frt
        next_response_time_threshold: 1.hour, # Miss nrt multiple times
        resolution_time_threshold: 4.hours # Miss rt
      )

      # Simulate conversation timeline
      # Hit frt
      # incoming message from customer
      create(:message, conversation: conversation, created_at: 6.hours.ago, message_type: :incoming)
      # outgoing message from agent within frt
      create(:message, conversation: conversation, created_at: 5.hours.ago, message_type: :outgoing)

      # Miss nrt first time
      create(:message, conversation: conversation, created_at: 4.hours.ago, message_type: :incoming)
      described_class.new(applied_sla: applied_sla).perform

      # Miss nrt second time
      create(:message, conversation: conversation, created_at: 3.hours.ago, message_type: :incoming)
      described_class.new(applied_sla: applied_sla).perform

      # Conversation is resolved missing rt
      conversation.update(status: 'resolved')

      # this will not create a new notification for rt miss as conversation is resolved
      # but we would have already created an rt miss notification during previous evaluation
      described_class.new(applied_sla: applied_sla).perform
    end

    it 'updates the SLA status to missed' do
      # the status would be missed as the conversation is resolved
      expect(applied_sla.reload.sla_status).to eq('missed')
    end

    it 'creates necessary sla events' do
      expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'frt').count).to eq(0)
      expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'nrt').count).to eq(2)
      expect(SlaEvent.where(applied_sla: applied_sla, event_type: 'rt').count).to eq(1)
    end
  end

  describe 'Business Hours SLA evaluation' do
    let!(:inbox) { create(:inbox, account: account, working_hours_enabled: true, timezone: 'UTC') }
    let!(:conversation) do
      create(:conversation,
             created_at: '15.05.2024 09:00'.to_datetime, assignee: user_1,
             account: sla_policy.account,
             sla_policy: sla_policy,
             inbox: inbox)
    end
    let!(:applied_sla) { conversation.applied_sla }

    before do
      # Configure business hours: Mon-Fri 9 AM - 5 PM UTC
      (1..5).each do |day|
        create(:working_hour,
               inbox: inbox,
               day_of_week: day,
               open_hour: 9,
               open_minutes: 0,
               close_hour: 17,
               close_minutes: 0)
      end
      # Weekend closed
      [0, 6].each do |day|
        create(:working_hour,
               inbox: inbox,
               day_of_week: day,
               closed_all_day: true)
      end

      Time.zone = 'UTC'
      travel_to '15.05.2024 10:00'.to_datetime
      applied_sla.sla_policy.update(only_during_business_hours: true)
    end

    context 'when business hours are enabled and SLA policy requires it' do
      context 'when evaluating first response time with business hours' do
        before { applied_sla.sla_policy.update(first_response_time_threshold: 2.hours) }

        it 'does not miss FRT when within business hours deadline' do
          # Conversation created at 9 AM
          # 2 hour FRT would be due at 1 PM (within business hours)
          # Current time is 10 AM
          allow(Rails.logger).to receive(:warn)
          described_class.new(applied_sla: applied_sla).perform
          expect(Rails.logger).not_to have_received(:warn)
          expect(applied_sla.reload.sla_status).to eq('active')
        end

        it 'misses FRT when business hours deadline is exceeded' do
          travel_to '15.05.2024 13:01'.to_datetime
          # Conversation created at 9 AM
          # 2 hour business hours FRT would be due at 1 PM
          # Current time is 1:01 PM - should miss
          allow(Rails.logger).to receive(:warn)
          described_class.new(applied_sla: applied_sla).perform
          expect(Rails.logger).to have_received(:warn).with("SLA frt missed for conversation #{conversation.id} in account " \
                                                            "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
          expect(applied_sla.reload.sla_status).to eq('active_with_misses')
        end

        it 'extends deadline over weekend correctly' do
          # Create conversation on Friday at 4 PM
          conversation.update(created_at: '10.05.2024 16:00'.to_datetime)
          travel_to '13.05.2024 09:59'.to_datetime # Monday 9:59 AM

          # 2 hour FRT from Friday 4 PM should be due Monday 10 AM
          # (1 hour Friday + 1 hour Monday)
          # Current time Monday 9:59 AM - should not miss yet
          allow(Rails.logger).to receive(:warn)
          described_class.new(applied_sla: applied_sla).perform
          expect(Rails.logger).not_to have_received(:warn)
          expect(applied_sla.reload.sla_status).to eq('active')
        end
      end

      context 'when evaluating next response time with business hours' do
        before do
          applied_sla.sla_policy.update(next_response_time_threshold: 1.hour)
          conversation.update(
            first_reply_created_at: '15.05.2024 09:30'.to_datetime,
            waiting_since: '15.05.2024 10:00'.to_datetime
          )
        end

        it 'calculates NRT deadline correctly in business hours' do
          travel_to '15.05.2024 10:30'.to_datetime
          # Customer replied at 10 AM, 1 hour NRT should be due at 11 AM
          # Current time 10:30 AM - should not miss yet
          allow(Rails.logger).to receive(:warn)
          described_class.new(applied_sla: applied_sla).perform
          expect(Rails.logger).not_to have_received(:warn)
          expect(applied_sla.reload.sla_status).to eq('active')
        end

        it 'misses NRT when business hours deadline is exceeded' do
          travel_to '15.05.2024 11:01'.to_datetime
          # Customer replied at 10 AM, 1 hour NRT should be due at 11 AM
          # Current time 11:01 AM - should miss
          allow(Rails.logger).to receive(:warn)
          described_class.new(applied_sla: applied_sla).perform
          expect(Rails.logger).to have_received(:warn).with("SLA nrt missed for conversation #{conversation.id} in account " \
                                                            "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
          expect(applied_sla.reload.sla_status).to eq('active_with_misses')
        end
      end

      context 'when evaluating resolution time with business hours' do
        before { applied_sla.sla_policy.update(resolution_time_threshold: 4.hours) }

        it 'calculates RT deadline correctly in business hours' do
          travel_to '15.05.2024 12:00'.to_datetime
          # Conversation created at 9 AM, 4 hour RT should be due at 3 PM
          # Current time 12 PM - should not miss yet
          allow(Rails.logger).to receive(:warn)
          described_class.new(applied_sla: applied_sla).perform
          expect(Rails.logger).not_to have_received(:warn)
          expect(applied_sla.reload.sla_status).to eq('active')
        end

        it 'misses RT when business hours deadline is exceeded' do
          travel_to '15.05.2024 15:01'.to_datetime
          # Conversation created at 9 AM, 4 hour RT should be due at 3 PM
          # Current time 3:01 PM - should miss
          allow(Rails.logger).to receive(:warn)
          described_class.new(applied_sla: applied_sla).perform
          expect(Rails.logger).to have_received(:warn).with("SLA rt missed for conversation #{conversation.id} in account " \
                                                            "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
          expect(applied_sla.reload.sla_status).to eq('active_with_misses')
        end
      end

      context 'when SLA spans across multiple business days' do
        before { applied_sla.sla_policy.update(resolution_time_threshold: 10.hours) }

        it 'correctly calculates deadline across multiple business days' do
          # Conversation created Wednesday 4 PM
          conversation.update(created_at: '15.05.2024 16:00'.to_datetime)
          travel_to '16.05.2024 11:00'.to_datetime # Thursday 11 AM

          # 10 hour RT: Wed 4-5 PM (1h) + Thu 9-11 AM (2h) = 3h elapsed, 7h remaining
          # Deadline should be Friday at 2 PM (Thu 9-5 = 8h total = 7h remaining)
          allow(Rails.logger).to receive(:warn)
          described_class.new(applied_sla: applied_sla).perform
          expect(Rails.logger).not_to have_received(:warn)
          expect(applied_sla.reload.sla_status).to eq('active')
        end
      end

      context 'when SLA starts near end of business day' do
        before do
          applied_sla.sla_policy.update(first_response_time_threshold: 2.hours)
          conversation.update(created_at: '15.05.2024 16:30'.to_datetime) # 4:30 PM
        end

        it 'extends deadline to next business day' do
          travel_to '16.05.2024 10:29'.to_datetime # Next day 10:29 AM

          # Started 4:30 PM (30 min before close) + 2 hours = 1.5 hours into next day
          # Deadline should be 10:30 AM next day
          allow(Rails.logger).to receive(:warn)
          described_class.new(applied_sla: applied_sla).perform
          expect(Rails.logger).not_to have_received(:warn)
          expect(applied_sla.reload.sla_status).to eq('active')
        end
      end
    end

    context 'when business hours are disabled on inbox' do
      before do
        inbox.update(working_hours_enabled: false)
        applied_sla.sla_policy.update(first_response_time_threshold: 2.hours)
      end

      it 'falls back to calendar time calculation' do
        travel_to '15.05.2024 11:01'.to_datetime
        # Conversation created at 9 AM, 2 hour FRT would be due at 11 AM (calendar time)
        # Current time 11:01 AM - should miss with calendar time
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:warn)
        expect(applied_sla.reload.sla_status).to eq('active_with_misses')
      end
    end

    context 'when SLA policy has business hours disabled' do
      before do
        applied_sla.sla_policy.update(
          only_during_business_hours: false,
          first_response_time_threshold: 2.hours
        )
      end

      it 'falls back to calendar time calculation' do
        travel_to '15.05.2024 11:01'.to_datetime
        # Conversation created at 9 AM, 2 hour FRT would be due at 11 AM (calendar time)
        # Current time 11:01 AM - should miss with calendar time
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:warn)
        expect(applied_sla.reload.sla_status).to eq('active_with_misses')
      end
    end

    context 'when conversation starts outside business hours' do
      before do
        conversation.update(created_at: '18.05.2024 18:00'.to_datetime)
        applied_sla.sla_policy.update(first_response_time_threshold: 2.hours)
        travel_to '20.05.2024 10:00'.to_datetime # Monday 10 AM
        # Saturday 6 PM
      end

      it 'starts counting from next business hours' do
        # Conversation created Saturday 6 PM (outside business hours)
        # 2 hour FRT should start counting from Monday 9 AM
        # Deadline would be Monday 11 AM
        # Current time Monday 10 AM - should not miss yet
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).not_to have_received(:warn)
        expect(applied_sla.reload.sla_status).to eq('active')
      end
    end

    context 'when handling different timezones' do
      before do
        inbox.update(timezone: 'America/New_York')
        # Update working hours for EST timezone
        inbox.working_hours.destroy_all
        (1..5).each do |day|
          create(:working_hour,
                 inbox: inbox,
                 day_of_week: day,
                 open_hour: 9,
                 open_minutes: 0,
                 close_hour: 17,
                 close_minutes: 0)
        end
        applied_sla.sla_policy.update(first_response_time_threshold: 2.hours)
      end

      it 'correctly handles timezone conversions' do
        # Conversation created at 9 AM EST (2 PM UTC)
        conversation.update(created_at: Time.zone.parse('15.05.2024 09:00 EST'))
        # Test at 10:59 AM EST (3:59 PM UTC) - should not miss 2 hour SLA yet
        travel_to Time.zone.parse('15.05.2024 10:59 EST')

        # Should calculate business hours in the inbox timezone
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).not_to have_received(:warn)
        expect(applied_sla.reload.sla_status).to eq('active')
      end
    end

    context 'when no working hours are configured' do
      before do
        inbox.working_hours.destroy_all
        applied_sla.sla_policy.update(first_response_time_threshold: 2.hours)
      end

      it 'falls back to calendar time calculation' do
        travel_to '15.05.2024 11:01'.to_datetime
        # No working hours configured, should fall back to calendar time
        # Conversation at 9 AM + 2 hours = 11 AM deadline
        # Current time 11:01 AM - should miss
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:warn)
        expect(applied_sla.reload.sla_status).to eq('active_with_misses')
      end
    end
  end
end
