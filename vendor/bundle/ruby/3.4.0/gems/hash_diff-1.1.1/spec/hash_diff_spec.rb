require "spec_helper"

describe HashDiff do
  describe ".diff" do
    subject { described_class.diff left, right }

    let(:left) {
      { foo: "bar" }
    }
    let(:right) {
      { foo: "bar2" }
    }

    it { expect(subject).to eq({ foo: ['bar', 'bar2']}) }
  end

  describe ".left_diff" do
    subject { described_class.left_diff left, right }

    let(:left) {
      { foo: "bar" }
    }
    let(:right) {
      { foo: "bar2" }
    }

    it { expect(subject).to eq({ foo: 'bar2' }) }
  end

  describe ".right_diff" do
    subject { described_class.right_diff left, right }

    let(:left) {
      { foo: "bar" }
    }
    let(:right) {
      { foo: "bar2" }
    }

    it { expect(subject).to eq({ foo: 'bar' }) }
  end

  describe ".patch!" do
    before { described_class.patch! }

    it "patches #diff to Hash" do
      expect({}).to respond_to(:diff)
    end

    it "leaves Object alone" do
      expect(Object.new).not_to respond_to(:diff)
    end
  end
end
