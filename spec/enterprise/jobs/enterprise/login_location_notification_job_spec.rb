require 'rails_helper'

RSpec.describe Enterprise::LoginLocationNotificationJob do
  geo_result = Struct.new(:city, :country)

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:now) { Time.zone.now }
  let(:current_uuid) { SecureRandom.uuid }
  let(:geo) do
    {
      '10.0.0.1' => %w[Northtown Northland],
      '10.0.0.2' => %w[Northtown Northland],
      '20.0.0.9' => %w[Southtown Southland]
    }
  end

  before do
    create(:installation_config, name: 'LOGIN_LOCATION_NOTIFICATION_ENABLED', value: true)
    GlobalConfig.clear_cache
    lookup = instance_double(IpLookupService)
    allow(IpLookupService).to receive(:new).and_return(lookup)
    allow(lookup).to receive(:perform) do |ip|
      city, country = geo[ip]
      country && geo_result.new(city, country)
    end
  end

  def audit(ip, at, request_uuid: SecureRandom.uuid)
    Enterprise::AuditLog.create!(user_id: user.id, user_type: 'User', auditable_id: user.id, auditable_type: 'User',
                                 action: 'sign_in', remote_address: ip, request_uuid: request_uuid, created_at: at)
  end

  def run(ip)
    row = audit(ip, now, request_uuid: current_uuid)
    described_class.perform_now(user.id, user.email, { ip: ip, browser_name: 'Chrome', platform_name: 'macOS' }, row.id)
  end

  it 'emails on a new country, excluding the current sign-in itself from history' do
    audit('10.0.0.1', now - 3.days)
    expect { run('20.0.0.9') }.to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'still emails when two concurrent sign-ins from the same new country race each other' do
    audit('10.0.0.1', now - 3.days)
    first = audit('20.0.0.9', now, request_uuid: current_uuid)
    audit('20.0.0.9', now)
    expect do
      described_class.perform_now(user.id, user.email, { ip: '20.0.0.9', browser_name: 'Chrome', platform_name: 'macOS' }, first.id)
    end.to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'does not email when the country is already known' do
    audit('10.0.0.1', now - 3.days)
    expect { run('10.0.0.2') }.not_to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'emails when the country was last seen outside the history window' do
    audit('20.0.0.9', now - 100.days)
    audit('10.0.0.1', now - 3.days)
    expect { run('20.0.0.9') }.to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'emails on a dormant account returning after the window, even from a known country' do
    audit('10.0.0.1', now - 100.days)
    expect { run('10.0.0.2') }.to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'still emails on a new country even when many multi-account rows exist for one prior sign-in' do
    shared = SecureRandom.uuid
    60.times { audit('10.0.0.1', now - 3.days, request_uuid: shared) }
    expect { run('20.0.0.9') }.to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'does not email on the first sign-in (no prior history)' do
    expect { run('20.0.0.9') }.not_to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'does not email when the feature is disabled' do
    InstallationConfig.find_by(name: 'LOGIN_LOCATION_NOTIFICATION_ENABLED').update!(value: false)
    GlobalConfig.clear_cache
    audit('10.0.0.1', now - 3.days)
    expect { run('20.0.0.9') }.not_to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'does not email when the current IP cannot be geolocated' do
    audit('10.0.0.1', now - 3.days)
    expect { run('198.51.100.7') }.not_to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end
end
