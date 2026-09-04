require 'rails_helper'

RSpec.describe SocialChannels::ProviderNameBackfillService do
  let(:account) { create(:account) }
  let(:output) { StringIO.new }
  let(:sleeper) { instance_double(Proc, call: nil) }
  let(:instagram_details_service) { instance_double(Instagram::UserDetailsService, perform: { 'username' => 'acme_support' }) }
  let(:tiktok_client) { instance_double(Tiktok::Client, business_account_details: { username: 'acme_tiktok' }) }
  let(:facebook_page_details_service) do
    instance_double(Facebook::PageDetailsService, perform: { provider_name: 'Acme Facebook', instagram_id: nil })
  end

  before do
    allow(Instagram::UserDetailsService).to receive(:new).and_return(instagram_details_service)
    allow(Tiktok::Client).to receive(:new).and_return(tiktok_client)
    allow(Facebook::PageDetailsService).to receive(:new).and_return(facebook_page_details_service)
    allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
    stub_request(:post, %r{graph\.instagram\.com/.+/subscribed_apps}).to_return(status: 200)
  end

  it 'rotates across providers while applying a global limit' do
    instagram_channels = create_list(:channel_instagram, 2, account: account)
    tiktok_channel = create(:channel_tiktok, account: account)

    described_class.new(limit: 2, delay_seconds: 0, dry_run: false, output: output, sleeper: sleeper).perform

    expect(instagram_channels.count { |channel| channel.reload.provider_name == 'acme_support' }).to eq(1)
    expect(tiktok_channel.reload.provider_name).to eq('acme_tiktok')
  end

  it 'only processes blank provider names on active accounts with an inbox' do
    eligible_channel = create(:channel_instagram, account: account)
    populated_channel = create(:channel_instagram, account: account, provider_name: 'already_set')
    suspended_channel = create(:channel_instagram, account: create(:account, status: :suspended))
    other_account_channel = create(:channel_instagram, account: create(:account))
    missing_inbox_channel = build(:channel_instagram, account: account)
    missing_inbox_channel.save!

    described_class.new(
      account_id: account.id, provider: 'instagram', delay_seconds: 0, dry_run: false, output: output, sleeper: sleeper
    ).perform

    expect(eligible_channel.reload.provider_name).to eq('acme_support')
    expect(populated_channel.reload.provider_name).to eq('already_set')
    expect(suspended_channel.reload.provider_name).to be_nil
    expect(other_account_channel.reload.provider_name).to be_nil
    expect(missing_inbox_channel.reload.provider_name).to be_nil
  end

  it 'does not call providers or update records in dry-run mode' do
    channel = create(:channel_tiktok, account: account)

    summary = described_class.new(provider: 'tiktok', delay_seconds: 0, dry_run: true, output: output, sleeper: sleeper).perform

    expect(Tiktok::Client).not_to have_received(:new)
    expect(channel.reload.provider_name).to be_nil
    expect(summary[:tiktok]).to include(eligible: 1, attempted: 0, updated: 0)
  end

  it 'retries a transient provider error before updating the channel' do
    channel = create(:channel_instagram, account: account)
    attempts = 0
    allow(instagram_details_service).to receive(:perform) do
      attempts += 1
      raise Instagram::UserDetailsService::Error.new('rate limited', 429) if attempts == 1

      { 'username' => 'acme_support' }
    end

    described_class.new(provider: 'instagram', delay_seconds: 0, dry_run: false, output: output, sleeper: sleeper).perform

    expect(attempts).to eq(2)
    expect(channel.reload.provider_name).to eq('acme_support')
  end

  it 'continues after a provider error without exposing credentials' do
    failed_channel = create(:channel_facebook_page, account: account, inbox: nil)
    create(:inbox, account: account, channel: failed_channel)
    successful_channel = create(:channel_facebook_page, account: account, inbox: nil)
    create(:inbox, account: account, channel: successful_channel)
    authentication_error = Koala::Facebook::AuthenticationError.new(401, '{"error":"invalid token"}')
    requests = 0
    allow(facebook_page_details_service).to receive(:perform) do
      requests += 1
      raise authentication_error if requests == 1

      { provider_name: 'Acme Facebook', instagram_id: nil }
    end

    summary = described_class.new(provider: 'facebook', delay_seconds: 0, dry_run: false, output: output, sleeper: sleeper).perform

    expect(summary[:facebook]).to include(attempted: 2, updated: 1, skipped: 1, failed: 0)
    expect(failed_channel.reload.provider_name).to be_nil
    expect(successful_channel.reload.provider_name).to eq('Acme Facebook')
    expect(output.string).to include("channel_id=#{failed_channel.id}", 'error=Koala::Facebook::AuthenticationError')
    expect(output.string).not_to include('invalid token')
  end
end
