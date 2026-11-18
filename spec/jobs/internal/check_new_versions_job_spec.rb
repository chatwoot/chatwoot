require 'rails_helper'

RSpec.describe Internal::CheckNewVersionsJob do
  subject(:job) { described_class.perform_now }

  before do
    allow(Rails.env).to receive(:production?).and_return(true)
    Redis::Alfred.delete(Redis::Alfred::LATEST_CHATWOOT_VERSION)
  end

  describe '#perform' do
    context 'when GitHub API returns successful response' do
      before do
        stub_request(:get, 'https://api.github.com/repos/fazer-ai/chatwoot/releases/latest')
          .to_return(
            status: 200,
            body: { tag_name: 'v1.2.3' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'updates the latest chatwoot version in redis with v prefix removed' do
        expect(job).to be(true)
        expect(Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION)).to eq '1.2.3'
      end
    end

    context 'when tag name has no v prefix' do
      before do
        stub_request(:get, 'https://api.github.com/repos/fazer-ai/chatwoot/releases/latest')
          .to_return(
            status: 200,
            body: { tag_name: '1.2.3' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'handles tag names without v prefix' do
        job

        expect(Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION)).to eq '1.2.3'
      end
    end

    # `Net::HTTP` repeats an idempotent request once by default, so this job's five seconds
    # were ten against a GitHub that accepts the connection and then stalls, on a schedule.
    it 'asks once, so the ceiling it advertises is the one it spends' do
      options = nil
      allow(HTTParty).to receive(:get) do |_url, **kwargs|
        options = kwargs
        instance_double(HTTParty::Response, success?: false, code: 500, body: '')
      end
      allow(Rails.logger).to receive(:error)

      job

      expect(options).to eq(timeout: 5, max_retries: 0)
    end

    context 'when GitHub API returns failed response' do
      before do
        stub_request(:get, 'https://api.github.com/repos/fazer-ai/chatwoot/releases/latest')
          .to_return(status: 404)
        allow(Rails.logger).to receive(:error)
      end

      it 'does not update redis when response is not successful' do
        expect { job }.not_to change { Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION) }.from(nil)
        expect(Rails.logger).to have_received(:error).with(/Failed to fetch latest GitHub release: HTTP 404 - /)
      end

      it 'answers false, so the Super Admin refresh reports the failure' do
        expect(job).to be(false)
      end
    end

    context 'when GitHub API raises an error' do
      let(:error_message) { 'Network timeout' }

      before do
        stub_request(:get, 'https://api.github.com/repos/fazer-ai/chatwoot/releases/latest')
          .to_raise(StandardError.new(error_message))
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error and does not update redis' do
        expect { job }.not_to change { Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION) }.from(nil)
        expect(Rails.logger).to have_received(:error).with("Failed to fetch latest GitHub release: #{error_message}")
      end
    end

    context 'when not in production environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it 'does not make any API calls or update redis' do
        expect { job }.not_to change { Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION) }.from(nil)
        expect(a_request(:get, 'https://api.github.com/repos/fazer-ai/chatwoot/releases/latest')).not_to have_been_made
      end
    end

    context 'when tag_name is nil' do
      before do
        stub_request(:get, 'https://api.github.com/repos/fazer-ai/chatwoot/releases/latest')
          .to_return(
            status: 200,
            body: { tag_name: nil }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'does not update redis when tag_name is nil' do
        expect { job }.not_to change { Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION) }.from(nil)
      end
    end
  end
end
