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

      it 'still turns call hours off' do
        channel.update!(provider_config: channel.provider_config.merge('business_hours_calls_enabled' => false))
        stub_meta_settings(nil)
        update = stub_update(call_hours('DISABLED', []))

        channel.apply_call_hours!

        expect(update).to have_been_requested
      end
    end
  end
end
