require 'rails_helper'
require 'sentry-ruby'

describe 'Webhook token path filter', type: :request do
  let(:token) { 'f3c9a1b27e604d5c8b0a9e1d2c3b4a59' }
  let(:channel) { create(:channel_whatsapp, provider: 'zapi', sync_templates: false, validate_provider_config: false) }

  # The "Started POST" line and lograge's `path` both come from `request.filtered_path`, the
  # second through this payload.
  it 'keeps the Z-API token out of the logged request path' do
    log = StringIO.new
    logged_paths = []
    subscriber = ActiveSupport::Notifications.subscribe('process_action.action_controller') { |*, payload| logged_paths << payload[:path] }
    allow(Rails).to receive(:logger).and_return(ActiveSupport::Logger.new(log))

    post "/webhooks/whatsapp/zapi/#{channel.id}/#{token}", params: { instanceId: 'instance' }

    ActiveSupport::Notifications.unsubscribe(subscriber)
    expect(logged_paths).to eq(["/webhooks/whatsapp/zapi/#{channel.id}/[FILTERED]"])
    expect(log.string).to include("Started POST \"/webhooks/whatsapp/zapi/#{channel.id}/[FILTERED]\"")
    expect(log.string).not_to include(token)
  end

  it 'masks the uazapi token and leaves other paths alone' do
    expect(WebhookTokenPathFilter.filter("/webhooks/whatsapp/session/uazapi/7/#{token}?x=1"))
      .to eq('/webhooks/whatsapp/session/uazapi/7/[FILTERED]?x=1')
    expect(WebhookTokenPathFilter.filter('/webhooks/whatsapp/5511999999999')).to eq('/webhooks/whatsapp/5511999999999')
  end

  it 'keeps the token out of the URL and transaction name sent to Sentry' do
    event = Sentry::ErrorEvent.new(configuration: Sentry::Configuration.new)
    event.rack_env = (Rack::MockRequest.env_for("https://chat.example.com/webhooks/whatsapp/zapi/#{channel.id}/#{token}", method: 'POST'))
    event.transaction = "/webhooks/whatsapp/zapi/#{channel.id}/#{token}"

    WebhookTokenPathFilter.filter_sentry_event(event)

    expect(event.request.url).to eq("https://chat.example.com/webhooks/whatsapp/zapi/#{channel.id}/[FILTERED]")
    expect(event.transaction).to eq("/webhooks/whatsapp/zapi/#{channel.id}/[FILTERED]")
  end
end
