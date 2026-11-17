require 'rails_helper'

RSpec.describe Channel::Whatsapp do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:weekdays) do
    %w[MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY].map do |day|
      { 'day_of_week' => day, 'open_time' => '0900', 'close_time' => '1700' }
    end
  end

  before do
    account.enable_features!('channel_voice')
    channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => true))
    inbox.update!(working_hours_enabled: true, timezone: 'America/Los_Angeles')
  end

  def apply_business_hours(enabled)
    channel.update!(provider_config: channel.provider_config.merge('business_hours_calls_enabled' => enabled))
  end

  describe '#desired_call_hours' do
    it 'maps the open days of the inbox to Meta weekdays in the inbox timezone' do
      apply_business_hours(true)

      expect(channel.desired_call_hours).to eq(
        'status' => 'ENABLED', 'timezone_id' => 'America/Los_Angeles', 'weekly_operating_hours' => weekdays
      )
    end

    it 'sends an all-day as the full day Chatwoot stores' do
      apply_business_hours(true)
      inbox.working_hours.find_by(day_of_week: 6).update!(closed_all_day: false, open_all_day: true)

      expect(channel.desired_call_hours['weekly_operating_hours'].last)
        .to eq('day_of_week' => 'SATURDAY', 'open_time' => '0000', 'close_time' => '2359')
    end

    it 'is disabled while the inbox business hours are off' do
      apply_business_hours(true)
      inbox.update!(working_hours_enabled: false)

      expect(channel.desired_call_hours['status']).to eq('DISABLED')
    end
  end

  describe '#call_hours_schedule_valid' do
    before { inbox.working_hours.update_all(closed_all_day: true) } # rubocop:disable Rails/SkipsModelValidations

    it 'needs an open day while business hours apply to calls' do
      apply_business_hours(true)

      channel.call_hours_schedule_valid

      expect(channel.errors.full_messages).to eq([I18n.t('inbox.call_hours.closed_every_day')])
    end

    it 'allows a closed week while business hours are not applied to calls' do
      apply_business_hours(false)

      channel.call_hours_schedule_valid

      expect(channel.errors).to be_empty
    end

    it 'allows a closed week while the inbox business hours are off' do
      apply_business_hours(true)
      inbox.update!(working_hours_enabled: false)

      channel.reload.call_hours_schedule_valid

      expect(channel.errors).to be_empty
    end
  end

  describe '#schedule_call_hours_sync' do
    it 'leaves a number alone until business hours are applied to calls' do
      expect { channel.schedule_call_hours_sync }.not_to have_enqueued_job(Whatsapp::SyncCallHoursJob)
      expect(channel.reload.call_hours_sync_status).to be_nil
    end

    it 'queues a sync and marks it pending once applied' do
      apply_business_hours(true)

      expect { channel.schedule_call_hours_sync }.to have_enqueued_job(Whatsapp::SyncCallHoursJob).with(channel)
      expect(channel.reload.call_hours_sync_status).to eq('pending')
    end

    context 'when Meta already has the current hours' do
      before do
        apply_business_hours(true)
        channel.record_call_hours_synced(channel.desired_call_hours.merge('holiday_schedule' => []))
      end

      it 'skips an unchanged save and keeps it synced' do
        expect { channel.schedule_call_hours_sync }.not_to have_enqueued_job(Whatsapp::SyncCallHoursJob)
        expect(channel.reload.call_hours_sync_status).to eq('synced')
      end

      it 'resends them when asked to' do
        expect { channel.schedule_call_hours_sync(force: true) }.to have_enqueued_job(Whatsapp::SyncCallHoursJob)
      end

      it 'syncs edited hours' do
        inbox.working_hours.find_by(day_of_week: 1).update!(close_hour: 18)

        expect { channel.schedule_call_hours_sync }.to have_enqueued_job(Whatsapp::SyncCallHoursJob)
      end

      it 'syncs turning business hours off for calls even while calling is off' do
        channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => false))
        apply_business_hours(false)

        expect { channel.schedule_call_hours_sync }.to have_enqueued_job(Whatsapp::SyncCallHoursJob)
      end

      it 'waits for calling to be back on before sending edited hours' do
        channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => false))
        inbox.working_hours.find_by(day_of_week: 1).update!(close_hour: 18)

        expect { channel.schedule_call_hours_sync }.not_to have_enqueued_job(Whatsapp::SyncCallHoursJob)
      end
    end

    it 'does not resend hours edited while call hours are off at Meta' do
      apply_business_hours(false)
      channel.record_call_hours_synced(channel.desired_call_hours)
      inbox.working_hours.find_by(day_of_week: 1).update!(close_hour: 18)

      expect { channel.schedule_call_hours_sync }.not_to have_enqueued_job(Whatsapp::SyncCallHoursJob)
    end

    it 'clears a failed first sync once business hours are no longer applied' do
      channel.record_call_hours_sync_failed('Not eligible')

      channel.schedule_call_hours_sync

      expect(channel.reload).to have_attributes(call_hours_sync_status: nil, call_hours_sync_error: nil)
    end
  end

  describe '#enable_voice_calling!' do
    it 'sends hours that were applied while calling was off' do
      channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => false))
      apply_business_hours(true)
      provider = instance_double(Whatsapp::Providers::WhatsappCloudService, update_calling_status: true)
      allow(channel).to receive(:provider_service).and_return(provider)
      allow(channel).to receive(:webhook_setup_service).and_return(instance_double(Whatsapp::WebhookSetupService, register_callback: true))

      expect { channel.enable_voice_calling! }.to have_enqueued_job(Whatsapp::SyncCallHoursJob).with(channel)
    end
  end
end
