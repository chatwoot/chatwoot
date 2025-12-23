describe Retriable::Config do
  let(:default_config) { described_class.new }

  context "defaults" do
    it "sleep defaults to enabled" do
      expect(default_config.sleep_disabled).to be_falsey
    end

    it "tries defaults to 3" do
      expect(default_config.tries).to eq(3)
    end

    it "max interval defaults to 60" do
      expect(default_config.max_interval).to eq(60)
    end

    it "randomization factor defaults to 0.5" do
      expect(default_config.base_interval).to eq(0.5)
    end

    it "multiplier defaults to 1.5" do
      expect(default_config.multiplier).to eq(1.5)
    end

    it "max elapsed time defaults to 900" do
      expect(default_config.max_elapsed_time).to eq(900)
    end

    it "intervals defaults to nil" do
      expect(default_config.intervals).to be_nil
    end

    it "timeout defaults to nil" do
      expect(default_config.timeout).to be_nil
    end

    it "on defaults to [StandardError]" do
      expect(default_config.on).to eq([StandardError])
    end

    it "on_retry handler defaults to nil" do
      expect(default_config.on_retry).to be_nil
    end

    it "contexts defaults to {}" do
      expect(default_config.contexts).to eq({})
    end
  end

  it "raises errors on invalid configuration" do
    expect { described_class.new(does_not_exist: 123) }.to raise_error(ArgumentError, /not a valid option/)
  end
end
