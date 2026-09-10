require 'rails_helper'

RSpec.describe ChatwootApp do
  describe '.self_hosted_paid?' do
    before do
      allow(described_class).to receive(:enterprise?).and_return(true)
      allow(described_class).to receive(:chatwoot_cloud?).and_return(false)
    end

    %w[premium enterprise].each do |plan|
      it "allows self-hosted #{plan}" do
        allow(ChatwootHub).to receive(:pricing_plan).and_return(plan)

        expect(described_class.self_hosted_paid?).to be(true)
      end
    end

    ['community', '', nil, 'unexpected'].each do |plan|
      it "rejects #{plan.inspect}" do
        allow(ChatwootHub).to receive(:pricing_plan).and_return(plan)

        expect(described_class.self_hosted_paid?).to be(false)
      end
    end

    it 'excludes Cloud' do
      allow(described_class).to receive(:chatwoot_cloud?).and_return(true)
      allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')

      expect(described_class.self_hosted_paid?).to be(false)
    end

    it 'requires enterprise code' do
      allow(described_class).to receive(:enterprise?).and_return(false)
      allow(ChatwootHub).to receive(:pricing_plan).and_return('premium')

      expect(described_class.self_hosted_paid?).to be(false)
    end
  end
end
