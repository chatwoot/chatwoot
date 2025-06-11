require 'rails_helper'

RSpec.describe Internal::AccountAnalysis::WebsiteScraperService do
  describe '#perform' do
    let(:service) { described_class.new(domain) }
    let(:html_content) { '<html><body>This is sample website content</body></html>' }

    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
    end

    context 'when domain is nil' do
      let(:domain) { nil }

      it 'returns nil' do
        expect(service.perform).to be_nil
      end
    end

    context 'when domain is present' do
      let(:domain) { 'example.com' }

      before do
        allow(HTTParty).to receive(:get).and_return(html_content)
      end

      it 'returns the stripped and normalized content' do
        expect(service.perform).to eq(html_content)
      end
    end

    context 'when an error occurs' do
      let(:domain) { 'example.com' }

      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new('Error'))
      end

      it 'returns nil' do
        expect(service.perform).to be_nil
      end
    end
  end
end
