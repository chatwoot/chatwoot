require 'spec_helper'
require 'bundler/audit/database'
require 'bundler/audit/advisory'

describe Bundler::Audit::Advisory do
  let(:root) { Fixtures::DATABASE_PATH }
  let(:gem)  { 'test' }
  let(:id)   { 'CVE-2020-1234' }
  let(:path) { Fixtures.join('advisory',"#{id}.yml") }

  subject { described_class.load(path) }

  let(:a_patched_version) do
    subject.patched_versions.map { |version_rule|
      # For all the rules, get the individual constraints out and see if we
      # can find a suitable one...
      version_rule.requirements.select { |(constraint, gem_version)|
        # We only want constraints where the version number specified is
        # one of the unaffected version.  I.E. we don't want ">", "<", or if
        # such a thing exists, "!=" constraints.
        ['~>', '>=', '=', '<='].include?(constraint)
      }.map { |(constraint, gem_version)|
        # Fetch just the version component, which is a Gem::Version,
        # and extract the string representation of the version.
        gem_version.version
      }
    }.flatten.first
  end

  let(:an_unaffected_version) do
    subject.unaffected_versions.map { |version_rule|
      # For all the rules, get the individual constraints out and see if we
      # can find a suitable one...
      version_rule.requirements.select { |(constraint, gem_version)|
        # We only want constraints where the version number specified is
        # one of the unaffected version.  I.E. we don't want ">", "<", or if
        # such a thing exists, "!=" constraints.
        ['~>', '>=', '=', '<='].include?(constraint)
      }.map { |(constraint, gem_version)|
        # Fetch just the version component, which is a Gem::Version,
        # and extract the string representation of the version.
        gem_version.version
      }
    }.flatten.first
  end

  describe "load" do
    let(:data) do
      File.open(path) do |yaml|
        if Psych::VERSION >= '3.1.0'
          YAML.safe_load(yaml, permitted_classes: [Date])
        else
          # XXX: psych < 3.1.0 YAML.safe_load calling convention
          YAML.safe_load(yaml, [Date])
        end
      end
    end

    describe '#id' do
      subject { super().id }
      it { is_expected.to eq(id)                  }
    end

    describe '#url' do
      subject { super().url }
      it { is_expected.to eq(data['url'])         }
    end

    describe '#title' do
      subject { super().title }
      it { is_expected.to eq(data['title'])       }
    end

    describe '#date' do
      subject { super().date }
      it { is_expected.to eq(data['date'])        }
    end

    describe '#cvss_v2' do
      subject { super().cvss_v2 }
      it { is_expected.to eq(data['cvss_v2'])     }
    end

    describe '#cvss_v3' do
      subject { super().cvss_v3 }
      it { is_expected.to eq(data['cvss_v3'])     }
    end

    describe '#description' do
      subject { super().description }
      it { is_expected.to eq(data['description']) }
    end

    context "YAML data not representing a hash" do
      let(:path) do
        File.expand_path('../fixtures/advisory/not_a_hash.yml', __FILE__)
      end

      it "should raise an exception" do
        expect {
          Advisory.load(path)
        }.to raise_exception("advisory data in #{path.dump} was not a Hash")
      end
    end

    describe "#patched_versions" do
      subject { described_class.load(path).patched_versions }

      it "should all be Gem::Requirement objects" do
        expect(subject.all? { |version|
          expect(version).to be_kind_of(Gem::Requirement)
        }).to be_truthy
      end

      it "should parse the versions" do
        expect(subject.map(&:to_s)).to eq(data['patched_versions'])
      end
    end
  end

  describe "#cve_id" do
    let(:cve) { "2015-1234" }

    subject do
      described_class.new.tap do |advisory|
        advisory.cve = cve
      end
    end

    it "should prepend CVE- to the CVE id" do
      expect(subject.cve_id).to be == "CVE-#{cve}"
    end

    context "when cve is nil" do
      subject { described_class.new }

      it { expect(subject.cve_id).to be_nil }
    end
  end

  describe "#osvdb_id" do
    let(:osvdb) { "123456" }

    subject do
      described_class.new.tap do |advisory|
        advisory.osvdb = osvdb
      end
    end

    it "should prepend OSVDB- to the OSVDB id" do
      expect(subject.osvdb_id).to be == "OSVDB-#{osvdb}"
    end

    context "when cve is nil" do
      subject { described_class.new }

      it { expect(subject.osvdb_id).to be_nil }
    end
  end

  describe "#ghsa_id" do
    let(:ghsa) { "xfhh-rx56-rxcr" }

    subject do
      described_class.new.tap do |advisory|
        advisory.ghsa = ghsa
      end
    end

    it "should prepend GHSA- to the GHSA id" do
      expect(subject.ghsa_id).to be == "GHSA-#{ghsa}"
    end

    context "when ghsa is nil" do
      subject { described_class.new }

      it { expect(subject.ghsa_id).to be_nil }
    end
  end

  describe "#identifiers" do
    it "should include all identifiers if defined" do
      advisory = described_class.new.tap do |advisory|
        advisory.cve = "2018-1234"
        advisory.osvdb = "2019-2345"
        advisory.ghsa = "2020-3456"
      end

      expect(advisory.identifiers).to eq([
        "CVE-2018-1234",
        "OSVDB-2019-2345",
        "GHSA-2020-3456"
      ])
    end

    it "should exclude nil identifiers" do
      advisory = described_class.new
      expect(advisory.identifiers).to eq([])

      advisory = described_class.new.tap do |advisory|
        advisory.cve = "2018-1234"
      end
      expect(advisory.identifiers).to eq(["CVE-2018-1234"])

      advisory = described_class.new.tap do |advisory|
        advisory.ghsa = "2020-3456"
      end
      expect(advisory.identifiers).to eq(["GHSA-2020-3456"])
    end
  end

  describe "#criticality" do
    context "when cvss_v2 is between 0.0 and 3.9" do
      subject do
        described_class.new.tap do |advisory|
          advisory.cvss_v2 = 3.9
        end
      end

      it { expect(subject.criticality).to eq(:low) }
    end

    context "when cvss_v2 is between 4.0 and 6.9" do
      subject do
        described_class.new.tap do |advisory|
          advisory.cvss_v2 = 6.9
        end
      end

      it { expect(subject.criticality).to eq(:medium) }
    end

    context "when cvss_v2 is between 7.0 and 10.0" do
      subject do
        described_class.new.tap do |advisory|
          advisory.cvss_v2 = 10.0
        end
      end

      it { expect(subject.criticality).to eq(:high) }
    end

    context "when cvss_v3 is 0.0" do
      subject do
        described_class.new.tap do |advisory|
          advisory.cvss_v3 = 0.0
        end
      end

      it { expect(subject.criticality).to eq(:none) }
    end

    context "when cvss_v3 is between 0.1 and 3.9" do
      subject do
        described_class.new.tap do |advisory|
          advisory.cvss_v3 = 3.9
        end
      end

      it { expect(subject.criticality).to eq(:low) }
    end

    context "when cvss_v3 is between 4.0 and 6.9" do
      subject do
        described_class.new.tap do |advisory|
          advisory.cvss_v3 = 6.9
        end
      end

      it { expect(subject.criticality).to eq(:medium) }
    end

    context "when cvss_v3 is between 7.0 and 8.9" do
      subject do
        described_class.new.tap do |advisory|
          advisory.cvss_v3 = 8.9
        end
      end

      it { expect(subject.criticality).to eq(:high) }
    end

    context "when cvss_v3 is between 9.0 and 10.0" do
      subject do
        described_class.new.tap do |advisory|
          advisory.cvss_v3 = 10.0
        end
      end

      it { expect(subject.criticality).to eq(:critical) }
    end
  end

  describe "#unaffected?" do
    context "when passed a version that matches one unaffected version" do
      let(:version) { Gem::Version.new(an_unaffected_version) }

      it "should return true" do
        expect(subject.unaffected?(version)).to be_truthy
      end
    end

    context "when passed a version that matches no unaffected version" do
      let(:version) { Gem::Version.new('3.0.9') }

      it "should return false" do
        expect(subject.unaffected?(version)).to be_falsey
      end
    end
  end

  describe "#patched?" do
    context "when passed a version that matches one patched version" do
      let(:version) { Gem::Version.new(a_patched_version) }

      it "should return true" do
        expect(subject.patched?(version)).to be_truthy
      end
    end

    context "when passed a version that matches no patched version" do
      let(:version) { Gem::Version.new('0.1.1') }

      it "should return false" do
        expect(subject.patched?(version)).to be_falsey
      end
    end
  end

  describe "#vulnerable?" do
    context "when passed a version that matches one patched version" do
      let(:version) { Gem::Version.new(a_patched_version) }

      it "should return false" do
        expect(subject.vulnerable?(version)).to be_falsey
      end
    end

    context "when passed a version that matches no patched version" do
      let(:version) { Gem::Version.new('0.1.1') }

      it "should return true" do
        expect(subject.vulnerable?(version)).to be_truthy
      end

      context "when unaffected_versions is not empty" do
        context "when passed a version that matches one unaffected version" do
          let(:version) { Gem::Version.new(an_unaffected_version) }

          it "should return false" do
            expect(subject.vulnerable?(version)).to be_falsey
          end
        end

        context "when passed a version that matches no unaffected version" do
          let(:version) { Gem::Version.new('0.1.0') }

          it "should return true" do
            expect(subject.vulnerable?(version)).to be_truthy
          end
        end
      end
    end
  end

  describe "#to_h" do
    subject { super().to_h }

    it "must include criticality: :critical" do
      expect(subject[:criticality]).to be :critical
    end
  end
end
