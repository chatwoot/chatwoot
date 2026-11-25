require 'rails_helper'

RSpec.describe Internal::CheckNewVersionsJob do
  subject(:job) { described_class.perform_now }

  # Every class is loaded before `enterprise?` is stubbed: `prepend_mod_with` asks it when a class
  # autoloads, and one first loaded under the stub (the job reaches Account and InstallationConfig)
  # would stay without Enterprise for every spec after this one in the same process. Only the first
  # call loads anything.
  before do
    Rails.application.eager_load!
    allow(Rails.env).to receive(:production?).and_return(true)
    allow(ChatwootApp).to receive(:enterprise?).and_return(false)
    Redis::Alfred.delete(Redis::Alfred::LATEST_CHATWOOT_VERSION)
  end

  context 'when the install runs Enterprise' do
    subject(:job) { described_class.perform_now(refresh_billing: true) }

    before { allow(ChatwootApp).to receive(:enterprise?).and_return(true) }

    it "syncs with Chatwoot's hub for the plan" do
      hub = stub_request(:post, ChatwootHub.ping_url).with(body: hash_including('refresh_billing' => true))
                                                     .to_return(status: 200, body: { version: '9.9.9', plan: 'community' }.to_json)

      expect(job).to be(true)
      expect(hub).to have_been_requested
      expect(Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION)).to be_nil
    end

    it 'answers false when the hub does not answer, so the refresh reports the failure' do
      stub_request(:post, ChatwootHub.ping_url).to_return(status: 503)

      expect(job).to be(false)
    end
  end

  describe '#perform' do
    it 'never looks up a newer release and answers true' do
      expect(job).to be(true)
      expect(a_request(:get, %r{api\.github\.com/repos/.+/releases/latest})).not_to have_been_made
      expect(a_request(:post, ChatwootHub.ping_url)).not_to have_been_made
    end

    it 'clears a version stored by an older build, so no update notice is shown' do
      Redis::Alfred.set(Redis::Alfred::LATEST_CHATWOOT_VERSION, '4.20.1-fazer-ai.152')

      job

      expect(Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION)).to be_nil
    end

    context 'when not in production environment' do
      before { allow(Rails.env).to receive(:production?).and_return(false) }

      it 'does nothing' do
        Redis::Alfred.set(Redis::Alfred::LATEST_CHATWOOT_VERSION, '4.20.1')

        job

        expect(Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION)).to eq '4.20.1'
      end
    end
  end
end
