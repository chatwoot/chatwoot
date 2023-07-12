# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/liquidable_shared.rb'

RSpec.describe Message do
  context 'with sentiment analysis' do
    let(:message) { build(:message, message_type: :incoming, content_type: nil, account: create(:account)) }

    it 'calls SentimentAnalysisJob' do
      allow(Enterprise::SentimentAnalysisJob).to receive(:perform_later).and_return(:perform_later).with(message)

      message.save!

      expect(Enterprise::SentimentAnalysisJob).to have_received(:perform_later)
    end
  end
end
