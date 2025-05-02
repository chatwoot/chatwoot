# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::AccountAnalysis::ThreatAnalyserService do
  subject { described_class.new(account) }

  let(:account) { create(:account) }
  let(:user) { create(:user, email: 'test@example.com', account: account) }
  let(:website_scraper) { instance_double(Internal::AccountAnalysis::WebsiteScraperService) }
  let(:content_evaluator) { instance_double(Internal::AccountAnalysis::ContentEvaluatorService) }
  let(:account_updater) { instance_double(Internal::AccountAnalysis::AccountUpdaterService) }
  let(:website_content) { 'This is the website content' }
  let(:threat_analysis) { { 'threat_level' => 'medium' } }

  before do
    user

    allow(Internal::AccountAnalysis::WebsiteScraperService).to receive(:new).with('example.com').and_return(website_scraper)
    allow(Internal::AccountAnalysis::ContentEvaluatorService).to receive(:new).and_return(content_evaluator)
    allow(Internal::AccountAnalysis::AccountUpdaterService).to receive(:new).with(account).and_return(account_updater)
  end

  describe '#perform' do
    before do
      allow(website_scraper).to receive(:perform).and_return(website_content)
      allow(content_evaluator).to receive(:evaluate).and_return(threat_analysis)
      allow(account_updater).to receive(:update_with_analysis)
      allow(Rails.logger).to receive(:info)
    end

    it 'performs threat analysis and updates the account' do
      expected_content = <<~MESSAGE
        Domain: example.com
        Content: This is the website content
      MESSAGE

      expect(website_scraper).to receive(:perform)
      expect(content_evaluator).to receive(:evaluate).with(expected_content)
      expect(account_updater).to receive(:update_with_analysis).with(threat_analysis)
      expect(Rails.logger).to receive(:info).with("Completed threat analysis: level=medium for account-id: #{account.id}")

      result = subject.perform
      expect(result).to eq(threat_analysis)
    end

    context 'when website content is blank' do
      before do
        allow(website_scraper).to receive(:perform).and_return(nil)
      end

      it 'logs info and updates account with error' do
        expect(Rails.logger).to receive(:info).with("Skipping threat analysis for account #{account.id}: No website content found")
        expect(account_updater).to receive(:update_with_analysis).with(nil, 'Scraping error: No content found')
        expect(content_evaluator).not_to receive(:evaluate)

        result = subject.perform
        expect(result).to be_nil
      end
    end
  end
end
