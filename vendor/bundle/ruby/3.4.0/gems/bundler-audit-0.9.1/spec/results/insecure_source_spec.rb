require 'spec_helper'
require 'bundler/audit/results/insecure_source'

describe Bundler::Audit::Results::InsecureSource do
  let(:source) { 'git://example.com/foo/bar.git' }

  subject { described_class.new(source) }

  describe "#initialize" do
    it "must set the source attribute" do
      expect(subject.source).to be(source)
    end
  end

  describe "#==" do
    context "when the other class is different" do
      let(:other) { Object.new }

      it "must return false" do
        expect(subject).to_not be == other
      end
    end

    context "when the source is different" do
      let(:other_source) { "https://example.com/other/repo.git" }
      let(:other) { described_class.new(other_source) }

      it "must return false" do
        expect(subject).to_not be == other
      end
    end

    context "when the source is the same" do
      let(:other) { described_class.new(source) }

      it "must return true" do
        expect(subject).to be == other
      end
    end
  end

  describe "#to_s" do
    it "should return the source attribute" do
      expect(subject.to_s).to be == source
    end
  end
end
