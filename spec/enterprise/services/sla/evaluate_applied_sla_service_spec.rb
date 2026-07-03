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

  describe '#perform - blocked contacts' do
    before do
      applied_sla.sla_policy.update(first_response_time_threshold: 1.hour, resolution_time_threshold: 1.hour)
      conversation.contact.update!(blocked: true)
    end

    it 'does not create SLA events or update SLA status' do
      described_class.new(applied_sla: applied_sla).perform

      expect(SlaEvent.where(applied_sla: applied_sla)).not_to exist
      expect(applied_sla.reload.sla_status).to eq('active')
    end

    it 'does not mark resolved conversations as hit or missed' do
      conversation.resolved!

      described_class.new(applied_sla: applied_sla).perform

      expect(SlaEvent.where(applied_sla: applied_sla)).not_to exist
      expect(applied_sla.reload.sla_status).to eq('active')
    end
  end

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

    context 'when first response SLA is hit after non-business hours' do
      let(:created_at) { Time.zone.parse('2026-06-25 00:39:56 UTC') }
      let(:wall_clock_breach_time) { Time.zone.parse('2026-06-25 01:40:03 UTC') }
      let(:first_reply_created_at) { Time.zone.parse('2026-06-25 11:45:36 UTC') }
      let(:post_reply_eval_time) { Time.zone.parse('2026-06-25 11:46:38 UTC') }
      let(:email_inbox) { create(:inbox, :with_email, account: account, working_hours_enabled: true, timezone: 'America/New_York') }
      let(:business_hours_sla_policy) do
        create(
          :sla_policy,
          account: account,
          first_response_time_threshold: 1.hour,
          next_response_time_threshold: nil,
          resolution_time_threshold: nil,
          only_during_business_hours: true
        )
      end
      let(:business_hours_conversation) do
        create(
          :conversation,
          account: account,
          inbox: email_inbox,
          sla_policy: business_hours_sla_policy,
          created_at: created_at,
          last_activity_at: created_at
        )
      end
      let(:business_hours_applied_sla) { business_hours_conversation.applied_sla }

      before do
        {
          0 => [11, 0, 20, 0],
          1 => [7, 0, 20, 0],
          2 => [7, 0, 20, 0],
          3 => [7, 0, 20, 0],
          4 => [7, 0, 16, 0],
          5 => [7, 0, 16, 0],
          6 => [11, 0, 20, 0]
        }.each do |day_of_week, (open_hour, open_minutes, close_hour, close_minutes)|
          email_inbox.working_hours.find_by(day_of_week: day_of_week).update!(
            open_hour: open_hour,
            open_minutes: open_minutes,
            close_hour: close_hour,
            close_minutes: close_minutes,
            closed_all_day: false,
            open_all_day: false
          )
        end
      end

      it 'does not mark FRT missed while outside business hours or after an on-time business-hours reply' do
        travel_to wall_clock_breach_time do
          described_class.new(applied_sla: business_hours_applied_sla).perform
        end

        business_hours_conversation.update!(first_reply_created_at: first_reply_created_at, last_activity_at: first_reply_created_at)

        travel_to post_reply_eval_time do
          described_class.new(applied_sla: business_hours_applied_sla).perform
        end

        expect(business_hours_applied_sla.reload.sla_status).to eq('active')
        expect(SlaEvent.where(applied_sla: business_hours_applied_sla, event_type: 'frt')).not_to exist
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
      create(:message, conversation: conversation, account: conversation.account, created_at: 6.hours.ago, message_type: :incoming)
      # outgoing message from agent within frt
      create(:message, conversation: conversation, account: conversation.account, created_at: 5.hours.ago, message_type: :outgoing)

      # Miss nrt first time
      create(:message, conversation: conversation, account: conversation.account, created_at: 4.hours.ago, message_type: :incoming)
      described_class.new(applied_sla: applied_sla).perform

      # Miss nrt second time
      create(:message, conversation: conversation, account: conversation.account, created_at: 3.hours.ago, message_type: :incoming)
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
end
