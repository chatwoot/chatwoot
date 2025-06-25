require 'rails_helper'

RSpec.describe Captain::Documents::CrawlJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:document) { create(:captain_document, assistant: assistant, account: account) }

  describe '#perform' do
    context 'when Firecrawl API key is configured' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: 'test_api_key')
      end

      it 'calls perform_firecrawl_crawl' do
        expect_any_instance_of(described_class).to receive(:perform_firecrawl_crawl).with(document)
        described_class.perform_now(document)
      end

      it 'handles PDF URLs correctly' do
        pdf_document = create(:captain_document, 
          assistant: assistant, 
          account: account,
          external_link: 'https://example.com/document.pdf'
        )
        
        expect(Captain::Tools::FirecrawlService).to receive_message_chain(:new, :perform)
          .with(pdf_document.external_link, anything, anything)
        
        described_class.perform_now(pdf_document)
      end
    end

    context 'when Firecrawl API key is not configured' do
      before do
        InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.destroy
      end

      it 'calls perform_simple_crawl' do
        expect_any_instance_of(described_class).to receive(:perform_simple_crawl).with(document)
        described_class.perform_now(document)
      end
    end

    context 'webhook URL generation' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: 'test_api_key')
      end

      it 'generates correct webhook URL with assistant_id and token' do
        job = described_class.new
        webhook_url = job.send(:firecrawl_webhook_url, document)
        
        expect(webhook_url).to include("assistant_id=#{document.assistant_id}")
        expect(webhook_url).to include('token=')
        expect(webhook_url).to include('/enterprise/webhooks/firecrawl')
      end
    end

    context 'crawl limit calculation' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: 'test_api_key')
      end

      it 'respects account usage limits' do
        allow(document.account).to receive(:usage_limits).and_return({
          captain: {
            documents: {
              current_available: 5
            }
          }
        })

        expect(Captain::Tools::FirecrawlService).to receive_message_chain(:new, :perform)
          .with(anything, anything, 5)
        
        described_class.perform_now(document)
      end

      it 'caps crawl limit at 500' do
        allow(document.account).to receive(:usage_limits).and_return({
          captain: {
            documents: {
              current_available: 1000
            }
          }
        })

        expect(Captain::Tools::FirecrawlService).to receive_message_chain(:new, :perform)
          .with(anything, anything, 500)
        
        described_class.perform_now(document)
      end
    end
  end
end