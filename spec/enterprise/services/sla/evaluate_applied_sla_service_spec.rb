require 'rails_helper'

RSpec.describe Sla::EvaluateAppliedSlaService do
  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }

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
      before { sla_policy.update(first_response_time_threshold: 1.hour) }

      it 'updates the SLA status to missed and logs a warning' do
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:warn).with("SLA missed for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
        expect(applied_sla.reload.sla_status).to eq('missed')

        expect(Notification.count).to eq(2)
        # check if notification type is sla_missed_first_response
        expect(Notification.where(notification_type: 'sla_missed_first_response').count).to eq(2)
        # Check if notification is created for the assignee
        expect(Notification.where(user_id: user_1.id).count).to eq(1)
        # Check if notification is created for the account admin
        expect(Notification.where(user_id: admin.id).count).to eq(1)
        # Check if no notification is created for other user
        expect(Notification.where(user_id: user_2.id).count).to eq(0)
      end
    end

    context 'when next response SLA is missed' do
      before do
        sla_policy.update(next_response_time_threshold: 1.hour)
        conversation.update(first_reply_created_at: 5.hours.ago, waiting_since: 5.hours.ago)
      end

      it 'updates the SLA status to missed and logs a warning' do
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:warn).with("SLA missed for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
        expect(applied_sla.reload.sla_status).to eq('missed')

        expect(Notification.count).to eq(2)
        # check if notification type is sla_missed_first_response
        expect(Notification.where(notification_type: 'sla_missed_next_response').count).to eq(2)
        # Check if notification is created for the assignee
        expect(Notification.where(user_id: user_1.id).count).to eq(1)
        # Check if notification is created for the account admin
        expect(Notification.where(user_id: admin.id).count).to eq(1)
        # Check if no notification is created for other user
        expect(Notification.where(user_id: user_2.id).count).to eq(0)
      end
    end

    context 'when resolution time SLA is missed' do
      before { sla_policy.update(resolution_time_threshold: 1.hour) }

      it 'updates the SLA status to missed and logs a warning' do
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:warn).with("SLA missed for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
        expect(applied_sla.reload.sla_status).to eq('missed')

        expect(Notification.count).to eq(2)
        expect(Notification.where(notification_type: 'sla_missed_resolution').count).to eq(2)
        # Check if notification is created for the assignee
        expect(Notification.where(user_id: user_1.id).count).to eq(1)
        # Check if notification is created for the account admin
        expect(Notification.where(user_id: admin.id).count).to eq(1)
        # Check if no notification is created for other user
        expect(Notification.where(user_id: user_2.id).count).to eq(0)
      end
    end

    # We will mark resolved miss only if while processing the SLA
    # if the conversation is resolved and the resolution time is missed by small margins then we will not mark it as missed
    context 'when resolved conversation with resolution time SLA is missed' do
      before do
        conversation.resolved!
        sla_policy.update(resolution_time_threshold: 1.hour)
      end

      it 'does not update the SLA status to missed' do
        described_class.new(applied_sla: applied_sla).perform
        expect(applied_sla.reload.sla_status).to eq('hit')
      end
    end

    context 'when multiple SLAs are missed' do
      before do
        sla_policy.update(first_response_time_threshold: 1.hour, next_response_time_threshold: 1.hour, resolution_time_threshold: 1.hour)
        conversation.update(first_reply_created_at: 5.hours.ago, waiting_since: 5.hours.ago)
      end

      it 'updates the SLA status to missed and logs a warning' do
        allow(Rails.logger).to receive(:warn)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:warn).with("SLA missed for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}").exactly(1).time
        expect(applied_sla.reload.sla_status).to eq('missed')
        expect(Notification.count).to eq(2)
      end
    end
  end

  describe '#perform - SLA hits' do
    context 'when first response SLA is hit' do
      before do
        sla_policy.update(first_response_time_threshold: 6.hours)
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
        expect(Notification.count).to eq(0)
      end
    end

    context 'when next response SLA is hit' do
      before do
        sla_policy.update(next_response_time_threshold: 6.hours)
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
      end
    end

    context 'when resolution time SLA is hit' do
      before do
        sla_policy.update(resolution_time_threshold: 8.hours)
        conversation.resolved!
      end

      it 'updates the SLA status to hit and logs an info' do
        allow(Rails.logger).to receive(:info)
        described_class.new(applied_sla: applied_sla).perform
        expect(Rails.logger).to have_received(:info).with("SLA hit for conversation #{conversation.id} in account " \
                                                          "#{applied_sla.account_id} for sla_policy #{sla_policy.id}")
        expect(applied_sla.reload.sla_status).to eq('hit')
      end
    end
  end
end
