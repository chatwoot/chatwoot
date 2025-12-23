require 'spec_helper'

describe WorkingHours::DurationProxy do
  describe '#initialize' do
    it 'is constructed with a value' do
      proxy = WorkingHours::DurationProxy.new(42)
      expect(proxy.value).to eq(42)
    end
  end

  context 'proxy methods' do

    let(:proxy) { WorkingHours::DurationProxy.new(42) }

    WorkingHours::Duration::SUPPORTED_KINDS.each do |kind|
      singular = kind[0..-2]

      it "##{kind} returns a duration object" do
        duration = proxy.send(kind)
        expect(duration.value).to eq(42)
        expect(duration.kind).to eq(kind)
      end

      it "##{singular} returns a duration object" do
        duration = proxy.send(singular)
        expect(duration.value).to eq(42)
        expect(duration.kind).to eq(kind)
      end
    end
  end
end
