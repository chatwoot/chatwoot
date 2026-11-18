require 'rails_helper'

RSpec.describe Whatsapp::CallHoursSyncService do
  subject(:sync) { described_class.new(channel: channel).perform }

  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:settings_url) { 'https://graph.facebook.com/v22.0/123456789/settings' }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:holidays) { [{ 'date' => '2026-12-25', 'start_time' => '0000', 'end_time' => '2359' }] }

  before do
    account.enable_features!('channel_voice')
    channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => true, 'business_hours_calls_enabled' => true))
    channel.inbox.update!(working_hours_enabled: true)
    channel.update!(call_hours_sync_status: 'pending')
  end

  def stub_meta_settings(call_hours)
    calling = call_hours.nil? ? { 'status' => 'ENABLED' } : { 'status' => 'ENABLED', 'call_hours' => call_hours }
    stub_request(:get, settings_url).to_return(status: 200, headers: headers, body: { calling: calling }.to_json)
  end

  def stub_update(expected_call_hours)
    stub_request(:post, settings_url)
      .with(body: { calling: { call_hours: expected_call_hours } }.to_json)
      .to_return(status: 200, headers: headers, body: { success: true }.to_json)
  end

  it 'sends the hours with the holidays Meta holds and records them as synced' do
    stub_meta_settings('status' => 'ENABLED', 'holiday_schedule' => holidays)
    expected = channel.desired_call_hours.merge('holiday_schedule' => holidays)
    update = stub_update(expected)

    sync

    expect(update).to have_been_requested
    expect(channel.reload).to have_attributes(call_hours_sync_status: 'synced', call_hours_sync_error: nil,
                                              call_hours_last_payload: expected)
    expect(channel.call_hours_synced_at).to be_present
  end

  it 'keeps an explicitly empty holiday list from Meta' do
    channel.update!(call_hours_last_payload: { 'status' => 'DISABLED', 'holiday_schedule' => holidays })
    stub_meta_settings('status' => 'DISABLED', 'holiday_schedule' => [])
    update = stub_update(channel.desired_call_hours.merge('holiday_schedule' => []))

    sync

    expect(update).to have_been_requested
  end

  it 'sends back the last holidays when Meta leaves them out while call hours are off' do
    channel.update!(call_hours_last_payload: { 'status' => 'DISABLED', 'holiday_schedule' => holidays })
    stub_meta_settings('status' => 'DISABLED')
    update = stub_update(channel.desired_call_hours.merge('holiday_schedule' => holidays))

    sync

    expect(update).to have_been_requested
  end

  it 'sends no holidays when there are none anywhere' do
    stub_meta_settings(nil)
    update = stub_update(channel.desired_call_hours)

    sync

    expect(update).to have_been_requested
  end

  it "records Meta's message when the update is refused" do
    stub_meta_settings(nil)
    error = { error: { message: 'Invalid timezone_id', error_user_msg: '' } }
    stub_request(:post, settings_url).to_return(status: 400, headers: headers, body: error.to_json)

    sync

    expect(channel.reload).to have_attributes(call_hours_sync_status: 'failed', call_hours_sync_error: 'Invalid timezone_id',
                                              call_hours_last_payload: nil)
  end

  def stub_update_with_change
    stub_request(:post, settings_url).to_return do
      yield
      { status: 200, headers: headers, body: { success: true }.to_json }
    end
  end

  it 'sends again when call hours were turned off while Meta was being updated' do
    stub_meta_settings(nil)
    # Saved the way the routing settings save it, without the remote credential check
    stub_update_with_change do
      saved = Channel::Whatsapp.find(channel.id)
      saved.provider_config = saved.provider_config.merge('business_hours_calls_enabled' => false)
      saved.save!(validate: false)
    end

    expect { sync }.to have_enqueued_job(Whatsapp::SyncCallHoursJob).with(channel)
    expect(channel.reload.call_hours_sync_status).to eq('pending')
  end

  it 'sends again when the timezone changed while Meta was being updated' do
    stub_meta_settings(nil)
    stub_update_with_change { Inbox.find(channel.inbox.id).update!(timezone: 'Asia/Kolkata') }

    expect { sync }.to have_enqueued_job(Whatsapp::SyncCallHoursJob).with(channel)
    expect(channel.reload.call_hours_sync_status).to eq('pending')
  end

  it 'tries settings saved during a refused update on their own' do
    stub_meta_settings(nil)
    stub_request(:post, settings_url).to_return do
      Inbox.find(channel.inbox.id).update!(timezone: 'Asia/Kolkata')
      { status: 400, headers: headers, body: { error: { message: 'Invalid timezone_id' } }.to_json }
    end

    expect { sync }.to have_enqueued_job(Whatsapp::SyncCallHoursJob).with(channel)
    expect(channel.reload).to have_attributes(call_hours_sync_status: 'pending', call_hours_sync_error: nil)
  end

  it 'does not retry a refused update on its own when nothing changed' do
    stub_meta_settings(nil)
    stub_request(:post, settings_url).to_return(status: 400, headers: headers, body: { error: { message: 'Invalid' } }.to_json)

    expect { sync }.not_to have_enqueued_job(Whatsapp::SyncCallHoursJob)
    expect(channel.reload.call_hours_sync_status).to eq('failed')
  end

  it 'sends again when the hours changed while Meta was being updated' do
    stub_meta_settings(nil)
    stub_request(:post, settings_url).to_return do
      channel.inbox.working_hours.find_by(day_of_week: 1).update!(close_hour: 18)
      { status: 200, headers: headers, body: { success: true }.to_json }
    end

    expect { sync }.to have_enqueued_job(Whatsapp::SyncCallHoursJob).with(channel)
    expect(channel.reload.call_hours_sync_status).to eq('pending')
  end
end
