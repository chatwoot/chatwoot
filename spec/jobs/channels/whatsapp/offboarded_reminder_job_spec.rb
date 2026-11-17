require 'rails_helper'

RSpec.describe Channels::Whatsapp::OffboardedReminderJob do
  let(:waba_id) { '980198427658004' }
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false).tap do |whatsapp_channel|
      embedded_signup_config = { 'source' => 'embedded_signup', 'business_account_id' => waba_id }
      whatsapp_channel.update!(provider_config: whatsapp_channel.provider_config.merge(embedded_signup_config))
    end
  end
  let(:offboarded_at) do
    channel
    Whatsapp::CoexistenceOffboarding.offboarded(waba_id)
    Redis::Alfred.get(Whatsapp::CoexistenceOffboarding.state_key(waba_id)).to_i
  end

  after { Redis::Alfred.delete(Whatsapp::CoexistenceOffboarding.state_key(waba_id)) }

  it 'emails the admins while the number is still offboarded' do
    expect { described_class.perform_now(waba_id, offboarded_at) }
      .to have_enqueued_mail(AdministratorNotifications::ChannelNotificationsMailer, :whatsapp_offboarded)
  end

  it 'does not email once Meta reconnected the number' do
    timestamp = offboarded_at
    Whatsapp::CoexistenceOffboarding.reconnected(waba_id)

    expect { described_class.perform_now(waba_id, timestamp) }
      .not_to have_enqueued_mail(AdministratorNotifications::ChannelNotificationsMailer, :whatsapp_offboarded)
  end

  it 'leaves a later offboard to its own reminder' do
    timestamp = offboarded_at

    expect { described_class.perform_now(waba_id, timestamp - 60) }
      .not_to have_enqueued_mail(AdministratorNotifications::ChannelNotificationsMailer, :whatsapp_offboarded)
  end

  it 'does not email for an inbox that already shows the reconnect banner' do
    timestamp = offboarded_at
    channel.prompt_reauthorization!

    expect { described_class.perform_now(waba_id, timestamp) }
      .not_to have_enqueued_mail(AdministratorNotifications::ChannelNotificationsMailer, :whatsapp_offboarded)
  end
end
