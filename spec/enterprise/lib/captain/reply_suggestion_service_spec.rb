require 'rails_helper'

RSpec.describe Captain::ReplySuggestionService do
  describe '#use_search_tool?' do
    subject(:use_search_tool?) { described_class.allocate.send(:use_search_tool?) }

    before do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
      allow(ChatwootApp).to receive(:self_hosted_enterprise?).and_return(false)
      allow(ChatwootHub).to receive(:pricing_plan).and_return('premium')
    end

    it { is_expected.to be(true) }
  end
end
