describe Retriable::ExponentialBackoff do
  context "defaults" do
    let(:backoff_config) { described_class.new }

    it "tries defaults to 3" do
      expect(backoff_config.tries).to eq(3)
    end

    it "max interval defaults to 60" do
      expect(backoff_config.max_interval).to eq(60)
    end

    it "randomization factor defaults to 0.5" do
      expect(backoff_config.base_interval).to eq(0.5)
    end

    it "multiplier defaults to 1.5" do
      expect(backoff_config.multiplier).to eq(1.5)
    end
  end

  it "generates 10 randomized intervals" do
    expect(described_class.new(tries: 9).intervals).to eq([
      0.5244067512211441,
      0.9113920238761231,
      1.2406087918999114,
      1.7632403621664823,
      2.338001204738311,
      4.350816718580626,
      5.339852157217869,
      11.889873261212443,
      18.756037881636484,
    ])
  end

  it "generates defined number of intervals" do
    expect(described_class.new(tries: 5).intervals.size).to eq(5)
  end

  it "generates intervals with a defined base interval" do
    expect(described_class.new(base_interval: 1).intervals).to eq([
      1.0488135024422882,
      1.8227840477522461,
      2.4812175837998227,
    ])
  end

  it "generates intervals with a defined multiplier" do
    expect(described_class.new(multiplier: 1).intervals).to eq([
      0.5244067512211441,
      0.607594682584082,
      0.5513816852888495,
    ])
  end

  it "generates intervals with a defined max interval" do
    expect(described_class.new(max_interval: 1.0, rand_factor: 0.0).intervals).to eq([0.5, 0.75, 1.0])
  end

  it "generates intervals with a defined rand_factor" do
    expect(described_class.new(rand_factor: 0.2).intervals).to eq([
      0.5097627004884576,
      0.8145568095504492,
      1.1712435167599646,
    ])
  end

  it "generates 10 non-randomized intervals" do
    non_random_intervals = 9.times.inject([0.5]) { |memo, _i| memo + [memo.last * 1.5] }
    expect(described_class.new(tries: 10, rand_factor: 0.0).intervals).to eq(non_random_intervals)
  end
end
