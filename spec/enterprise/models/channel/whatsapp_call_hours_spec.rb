require 'rails_helper'

RSpec.describe Channel::Whatsapp do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:settings_url) { 'https://graph.facebook.com/v22.0/123456789/settings' }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:holidays) { [{ 'date' => '2026-12-25', 'start_time' => '0000', 'end_time' => '2359' }] }
  let(:weekdays) do
    %w[MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY].map do |day|
      { 'day_of_week' => day, 'open_time' => '0900', 'close_time' => '1700' }
    end
  end

  before do
    account.enable_features!('channel_voice')
    channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => true, 'business_hours_calls_enabled' => true))
    inbox.update!(working_hours_enabled: true, timezone: 'America/Los_Angeles')
  end

  def stub_meta_settings(call_hours)
    calling = call_hours.nil? ? { 'status' => 'ENABLED' } : { 'status' => 'ENABLED', 'call_hours' => call_hours }
    stub_request(:get, settings_url).to_return(status: 200, headers: headers, body: { calling: calling }.to_json)
  end

  def stub_update(call_hours)
    stub_request(:post, settings_url)
      .with(body: { calling: { call_hours: call_hours } }.to_json)
      .to_return(status: 200, headers: headers, body: { success: true }.to_json)
  end

  def call_hours(status, weekly = weekdays)
    { 'status' => status, 'timezone_id' => 'America/Los_Angeles', 'weekly_operating_hours' => weekly }
  end

  describe '#apply_call_hours!' do
    it 'sends the open days in the inbox timezone, keeping the holidays WhatsApp holds' do
      stub_meta_settings('status' => 'ENABLED', 'holiday_schedule' => holidays)
      update = stub_update(call_hours('ENABLED').merge('holiday_schedule' => holidays))

      channel.apply_call_hours!

      expect(update).to have_been_requested
    end

    it 'sends no holidays when WhatsApp has none' do
      stub_meta_settings(nil)
      update = stub_update(call_hours('ENABLED'))

      channel.apply_call_hours!

      expect(update).to have_been_requested
    end

    it 'sends an all-day as the full day Chatwoot stores' do
      inbox.working_hours.find_by(day_of_week: 6).update!(closed_all_day: false, open_all_day: true)
      stub_meta_settings(nil)
      saturday = { 'day_of_week' => 'SATURDAY', 'open_time' => '0000', 'close_time' => '2359' }
      update = stub_update(call_hours('ENABLED', weekdays + [saturday]))

      channel.apply_call_hours!

      expect(update).to have_been_requested
    end

    it 'turns call hours off at WhatsApp once the inbox business hours are off' do
      inbox.update!(working_hours_enabled: false)
      stub_meta_settings(nil)
      update = stub_update(call_hours('DISABLED'))

      channel.reload.apply_call_hours!

      expect(update).to have_been_requested
    end

    it "raises WhatsApp's reason when it refuses the hours" do
      stub_meta_settings(nil)
      stub_request(:post, settings_url).to_return(
        status: 400, headers: headers, body: { error: { message: 'Invalid parameter', error_user_msg: 'Invalid timezone_id' } }.to_json
      )

      expect { channel.apply_call_hours! }.to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record.errors.full_messages).to eq([I18n.t('inbox.call_hours.whatsapp_failed', error: 'Invalid timezone_id')])
      }
    end

    context 'with every day closed' do
      before { inbox.working_hours.update_all(closed_all_day: true) } # rubocop:disable Rails/SkipsModelValidations

      it 'refuses to apply business hours without asking WhatsApp' do
        expect { channel.apply_call_hours! }.to raise_error(ActiveRecord::RecordInvalid) { |error|
          expect(error.record.errors.full_messages).to eq([I18n.t('inbox.call_hours.closed_every_day')])
        }
        expect(a_request(:any, settings_url)).not_to have_been_made
      end

      it "still turns call hours off, sending WhatsApp's own week since it refuses an empty one" do
        channel.update!(provider_config: channel.provider_config.merge('business_hours_calls_enabled' => false))
        stub_meta_settings(call_hours('ENABLED').merge('holiday_schedule' => holidays))
        update = stub_update(call_hours('DISABLED').merge('holiday_schedule' => holidays))

        channel.apply_call_hours!

        expect(update).to have_been_requested
      end

      it 'sends nothing when WhatsApp has no week, since call hours cannot be on there' do
        channel.update!(provider_config: channel.provider_config.merge('business_hours_calls_enabled' => false))
        stub_meta_settings(nil)

        channel.apply_call_hours!

        expect(a_request(:post, settings_url)).not_to have_been_made
      end
    end
  end

  describe '#call_hours_match_whatsapp?' do
    it 'matches when WhatsApp has the inbox hours, in any order and with its own holidays' do
      stub_meta_settings(call_hours('ENABLED', weekdays.reverse).merge('holiday_schedule' => holidays))

      expect(channel.call_hours_match_whatsapp?).to be(true)
    end

    it 'does not match hours changed in WhatsApp Manager' do
      edited = weekdays.map { |day| day.merge('close_time' => '1800') }
      stub_meta_settings(call_hours('ENABLED', edited))

      expect(channel.call_hours_match_whatsapp?).to be(false)
    end

    it 'does not match another timezone' do
      stub_meta_settings(call_hours('ENABLED').merge('timezone_id' => 'Asia/Kolkata'))

      expect(channel.call_hours_match_whatsapp?).to be(false)
    end

    it 'does not match call hours turned off in WhatsApp Manager' do
      stub_meta_settings(call_hours('DISABLED'))

      expect(channel.call_hours_match_whatsapp?).to be(false)
    end

    it 'matches no call hours at WhatsApp while business hours are not applied to calls' do
      channel.update!(provider_config: channel.provider_config.merge('business_hours_calls_enabled' => false))
      stub_meta_settings(nil)

      expect(channel.call_hours_match_whatsapp?).to be(true)
    end
  end

  describe '#enable_voice_calling!' do
    before do
      channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => false))
      allow(channel).to receive(:webhook_setup_service).and_return(instance_double(Whatsapp::WebhookSetupService, register_callback: true))
      stub_request(:post, settings_url).with { |request| JSON.parse(request.body).dig('calling', 'status') == 'ENABLED' }
                                       .to_return(status: 200, headers: headers, body: '{}')
    end

    it 'turns call hours off at WhatsApp when business hours were turned off while calling was off' do
      inbox.update!(working_hours_enabled: false)
      stub_meta_settings(call_hours('ENABLED'))
      update = stub_update(call_hours('DISABLED'))

      channel.reload.enable_voice_calling!

      expect(update).to have_been_requested
      expect(channel.reload.voice_enabled?).to be(true)
    end

    it 'keeps calling off when WhatsApp refuses the hours' do
      stub_meta_settings(nil)
      stub_request(:post, settings_url).with { |request| JSON.parse(request.body)['calling'].key?('call_hours') }
                                       .to_return(status: 400, headers: headers, body: { error: { error_user_msg: 'Invalid timezone_id' } }.to_json)

      expect { channel.enable_voice_calling! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(channel.reload.voice_enabled?).to be(false)
    end

    it 'leaves call hours alone when business hours are not applied to calls' do
      channel.update!(provider_config: channel.provider_config.merge('business_hours_calls_enabled' => false))

      channel.enable_voice_calling!

      expect(a_request(:get, settings_url)).not_to have_been_made
      expect(channel.reload.voice_enabled?).to be(true)
    end
  end
end
