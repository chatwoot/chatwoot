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

  it 'rotates across providers instead of exhausting one provider first' do
    instagram_channels = create_list(:channel_instagram, 2, account: account)
    tiktok_channel = create(:channel_tiktok, account: account)

    described_class.new(delay_seconds: 0, dry_run: false, output: output, sleeper: sleeper).perform

    updated_provider_order = output.string.scan(/\[updated\] provider=(\w+)/).flatten
    expect(updated_provider_order).to eq(%w[instagram tiktok instagram])
    expect(instagram_channels).to all(satisfy { |channel| channel.reload.provider_name == 'acme_support' })
    expect(tiktok_channel.reload.provider_name).to eq('acme_tiktok')
  end

  it 'resumes a provider-scoped limited run after permanently failed rows' do
    channels = create_list(:channel_tiktok, 3, account: account)
    allow(tiktok_client).to receive(:business_account_details).and_raise('permanent provider failure')

    first_summary = described_class.new(
      provider: 'tiktok', limit: 2, delay_seconds: 0, dry_run: false, output: output, sleeper: sleeper
    ).perform

    allow(tiktok_client).to receive(:business_account_details).and_return(username: 'acme_tiktok')
    second_summary = described_class.new(
      provider: 'tiktok', limit: 2, after_id: first_summary[:tiktok][:last_attempted_id],
      delay_seconds: 0, dry_run: false, output: output, sleeper: sleeper
    ).perform

    expect(first_summary[:tiktok]).to include(attempted: 2, failed: 2, remaining: 3, last_attempted_id: channels.second.id)
    expect(second_summary[:tiktok]).to include(attempted: 1, updated: 1, remaining: 2, last_attempted_id: channels.third.id)
    expect(channels.map { |channel| channel.reload.provider_name }).to eq([nil, nil, 'acme_tiktok'])
  end

  it 'rejects limited or cursor runs without a provider' do
    expect { described_class.new(limit: 10) }.to raise_error(ArgumentError, 'PROVIDER is required when LIMIT is set')
    expect { described_class.new(after_id: 10) }.to raise_error(ArgumentError, 'PROVIDER is required when AFTER_ID is set')
  end

  it 'rejects malformed numeric controls instead of silently coercing them', :aggregate_failures do
    expect { described_class.new(delay_seconds: 'oops') }
      .to raise_error(ArgumentError, 'DELAY_SECONDS must be a finite non-negative number')
    expect { described_class.new(delay_seconds: Float::INFINITY) }
      .to raise_error(ArgumentError, 'DELAY_SECONDS must be a finite non-negative number')
    expect { described_class.new(account_id: 'oops') }.to raise_error(ArgumentError, 'ACCOUNT_ID must be a positive integer')
    expect { described_class.new(provider: 'tiktok', limit: '1.5') }.to raise_error(ArgumentError, 'LIMIT must be a positive integer')
    expect { described_class.new(provider: 'tiktok', limit: 1.5) }.to raise_error(ArgumentError, 'LIMIT must be a positive integer')
    expect { described_class.new(provider: 'tiktok', after_id: -1) }
      .to raise_error(ArgumentError, 'AFTER_ID must be a non-negative integer')
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
