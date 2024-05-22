require 'rails_helper'

RSpec.describe V2::Reports::Conversations::MetricBuilder, type: :model do
  let(:account) { create(:account) }
  let(:params) { { since: '2023-01-01', until: '2024-01-01' } }
  let(:metric_builder) { described_class.new(account, params) }
  let(:count_builder_instance) { instance_double(V2::Reports::Timeseries::CountReportBuilder, aggregate_value: 42) }
  let(:avg_builder_instance) { instance_double(V2::Reports::Timeseries::AverageReportBuilder, aggregate_value: 42) }

  before do
    allow(V2::Reports::Timeseries::CountReportBuilder).to receive(:new).and_return(count_builder_instance)
    allow(V2::Reports::Timeseries::AverageReportBuilder).to receive(:new).and_return(avg_builder_instance)
  end

  shared_examples 'conversation metric builder' do |method, metric, builder_class|
    it "creates a new #{builder_class} with correct parameters" do
      metric_builder.send(method)
      expect(builder_class).to have_received(:new).with(account, params.merge(metric: metric))
    end
  end

  describe '#summary' do
    it 'returns a comprehensive summary of general conversation metrics' do
      summary = metric_builder.summary

      expected_summary = {
        conversations_count: 42,
        incoming_messages_count: 42,
        outgoing_messages_count: 42,
        avg_first_response_time: 42,
        avg_resolution_time: 42,
        resolutions_count: 42,
        reply_time: 42
      }
      expect(summary).to eq(expected_summary)
    end

    include_examples 'conversation metric builder', :summary, 'conversations_count', V2::Reports::Timeseries::CountReportBuilder
    include_examples 'conversation metric builder', :summary, 'incoming_messages_count', V2::Reports::Timeseries::CountReportBuilder
    include_examples 'conversation metric builder', :summary, 'outgoing_messages_count', V2::Reports::Timeseries::CountReportBuilder
    include_examples 'conversation metric builder', :summary, 'resolutions_count', V2::Reports::Timeseries::CountReportBuilder
    include_examples 'conversation metric builder', :summary, 'avg_first_response_time', V2::Reports::Timeseries::AverageReportBuilder
    include_examples 'conversation metric builder', :summary, 'avg_resolution_time', V2::Reports::Timeseries::AverageReportBuilder
    include_examples 'conversation metric builder', :summary, 'reply_time', V2::Reports::Timeseries::AverageReportBuilder
  end

  describe '#bot_summary' do
    it 'returns a detailed summary of bot-specific conversation metrics' do
      bot_summary = metric_builder.bot_summary

      expected_bot_summary = {
        bot_resolutions_count: 42,
        bot_handoffs_count: 42
      }
      expect(bot_summary).to eq(expected_bot_summary)
    end

    include_examples 'conversation metric builder', :bot_summary, 'bot_resolutions_count', V2::Reports::Timeseries::CountReportBuilder
    include_examples 'conversation metric builder', :bot_summary, 'bot_handoffs_count', V2::Reports::Timeseries::CountReportBuilder
  end
end
