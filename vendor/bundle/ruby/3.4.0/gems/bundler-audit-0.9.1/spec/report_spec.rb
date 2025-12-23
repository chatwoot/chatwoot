require 'spec_helper'
require 'bundler/audit/report'

describe Bundler::Audit::Report do
  let(:uri) { URI('git://github.com/foo/bar.git') }
  let(:insecure_source) do
    Bundler::Audit::Results::InsecureSource.new(uri)
  end

  let(:gem) do
    Gem::Specification.new do |spec|
      spec.name = 'test'
      spec.version = '0.0.0'
    end
  end
  let(:advisory) { double('Bundler::Audit::Advisory', id: 'CVE-3000-1234') }
  let(:unpatched_gem) do
    Bundler::Audit::Results::UnpatchedGem.new(gem,advisory)
  end

  let(:results) do
    [insecure_source, unpatched_gem]
  end

  subject { described_class.new(results) }

  describe "#version" do
    it "should be the VERSION constant" do
      expect(subject.version).to be(Bundler::Audit::VERSION)
    end
  end

  describe "#time" do
    it { expect(subject.created_at).to be_kind_of(Time) }
  end

  describe "#<<" do
    subject { described_class.new }

    it "should return self" do
      expect(subject << insecure_source).to be(subject)
    end

    context "when given a Result::InsecureSource" do
      let(:result) { insecure_source }

      before { subject << result }

      it "should add the result to the report" do
        expect(subject.results.last).to be(result)
      end

      it "should also add the result to #insecure_sources" do
        expect(subject.insecure_sources.last).to be(result)
      end
    end

    context "when given a Result::UnpatchedGem" do
      let(:result) { unpatched_gem }

      before { subject << result }

      it "should add the result to the report" do
        expect(subject.results.last).to be(result)
      end

      it "should also add the result to #unpatched_gems" do
        expect(subject.unpatched_gems.last).to be(result)
      end
    end
  end

  describe "#each" do
    context "when given a block" do
      it "should enumerate over each result in the report" do
        expect { |b| subject.each(&b) }.to yield_successive_args(*results)
      end
    end

    context "when no block is given" do
      it "should return an Enumerator" do
        expect(subject.each).to be_kind_of(Enumerator)
      end
    end
  end

  describe "#vulnerable?" do
    context "when the report is empty" do
      subject { described_class.new }

      it { expect(subject.vulnerable?).to be false }
    end

    context "when then report contains results" do
      it { expect(subject.vulnerable?).to be true }
    end
  end
end
