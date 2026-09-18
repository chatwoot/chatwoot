require 'rails_helper'

RSpec.describe Enterprise::LoginLocationNotificationJob do
  let(:account) { create(:account) }
  # IP -> [city, country]
  let(:geo) do
    {
      '10.0.0.1' => %w[Mumbai India],
      '10.0.0.2' => %w[Mumbai India],
      '20.0.0.9' => %w[Chisinau Moldova]
    }
  end
  let(:user) { create(:user, account: account) }
  let(:now) { Time.zone.now }

  geo_result = Struct.new(:city, :country)

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

  def prior_sign_in(ip, at)
    Enterprise::AuditLog.create!(user_id: user.id, user_type: 'User', auditable_id: user.id, auditable_type: 'User',
                                 action: 'sign_in', remote_address: ip, created_at: at)
  end

  def run(ip)
    described_class.perform_now(user.id, ip, 'Mozilla/5.0 Chrome', now.iso8601)
  end

  it 'emails when the country has not been seen before' do
    prior_sign_in('10.0.0.1', now - 3.days)
    expect { run('20.0.0.9') }.to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'does not email when the country is already known' do
    prior_sign_in('10.0.0.1', now - 3.days)
    expect { run('10.0.0.2') }.not_to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'does not email on the first sign-in (no prior history)' do
    expect { run('20.0.0.9') }.not_to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'does not email when the feature is disabled' do
    InstallationConfig.find_by(name: 'LOGIN_LOCATION_NOTIFICATION_ENABLED').update!(value: false)
    GlobalConfig.clear_cache
    prior_sign_in('10.0.0.1', now - 3.days)
    expect { run('20.0.0.9') }.not_to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end

  it 'does not email when the current IP cannot be geolocated' do
    prior_sign_in('10.0.0.1', now - 3.days)
    expect { run('198.51.100.7') }.not_to have_enqueued_mail(Enterprise::LoginLocationMailer, :new_location)
  end
end
