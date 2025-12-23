require 'spec_helper'
require 'bundler/audit/results/unpatched_gem'

describe Bundler::Audit::Results::UnpatchedGem do
  let(:gem) do
    Gem::Specification.new do |spec|
      spec.name = 'test'
      spec.version = '0.0.0'
    end
  end

  let(:advisory) do
    double('Bundler::Audit::Advisory', id: 'CVE-3000-1234')
  end

  subject { described_class.new(gem,advisory) }

  describe "#initialize" do
    it "must set the gem attribute" do
      expect(subject.gem).to be(gem)
    end

    it "must set the advisory attribute" do
      expect(subject.advisory).to be(advisory)
    end
  end

  describe "#==" do
    context "when the other class is different" do
      let(:other) { Object.new }

      it "should return false" do
        expect(subject).to_not be == other
      end
    end

    context "when the other gem name is different" do
      let(:other_gem) do
        Gem::Specification.new do |spec|
          spec.name = "#{gem.name}2"
          spec.version = gem.version
        end
      end

      let(:other) { described_class.new(other_gem,advisory) }

      it "must return false" do
        expect(subject).to_not be == other
      end
    end

    context "when the other gem version is different" do
      let(:other_gem) do
        Gem::Specification.new do |spec|
          spec.name = gem.name
          spec.version = "#{gem.version}.1"
        end
      end

      let(:other) { described_class.new(other_gem,advisory) }

      it "must return false" do
        expect(subject).to_not be == other
      end
    end

    context "when the other advisory is different" do
      let(:other_advisory) do
        double('Bundler::Audit::Advisory', id: 'CVE-3000-9876')
      end

      let(:other) { described_class.new(gem,other_advisory) }

      it "must return false" do
        expect(subject).to_not be == other
      end
    end

    context "when the gem and avisory are the same" do
      let(:other) { described_class.new(gem,advisory) }

      it "must return true" do
        expect(subject).to be == other
      end
    end
  end

  describe "#to_h" do
    subject { super().to_h }

    let(:advisory_hash) { {id: advisory.id} }

    before { expect(advisory).to receive(:to_h).and_return(advisory_hash) }

    it "must include type: :unpatched_gem" do
      expect(subject[:type]).to be :unpatched_gem
    end

    it "must include a :gem key containing a Hash" do
      expect(subject[:gem]).to be_kind_of(Hash)
    end

    context ":gem" do
      it "must contain a :name key of the gem name" do
        expect(subject[:gem][:name]).to be == gem.name
      end

      it "must contain a :version key of the gem name" do
        expect(subject[:gem][:version]).to be == gem.version
      end
    end

    it "must include a :advisory key containing a Hash of the advisory" do
      expect(subject[:advisory]).to be == advisory_hash
    end
  end

  describe "#to_s" do
    it "should return the advisory ID" do
      expect(subject.to_s).to be == advisory.id
    end
  end
end
