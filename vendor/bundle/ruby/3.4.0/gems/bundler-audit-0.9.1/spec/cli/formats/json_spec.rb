require 'spec_helper'
require 'bundler/audit/cli/formats'
require 'bundler/audit/cli/formats/json'
require 'bundler/audit/report'

describe Bundler::Audit::CLI::Formats::JSON do
  it "must register the 'json' format" do
    expect(Bundler::Audit::CLI::Formats[:json]).to be described_class
  end

  let(:options) { {} }

  subject do
    Bundler::Audit::CLI.new([],options).tap do |obj|
      obj.extend described_class
    end
  end

  describe "#print_report" do
    let(:report) { Bundler::Audit::Report.new }
    let(:stdout) { StringIO.new }

    before { subject.print_report(report,stdout) }

    let(:output) { stdout.string }
    let(:output_json) { JSON.parse(output, symbolize_names: true) }

    it "must output a JSON hash" do
      expect(output_json).to be_kind_of(Hash)
    end

    it 'must output a "version" key with the Bundler::Audit::VERSION' do
      expect(output_json[:version]).to be == Bundler::Audit::VERSION
    end

    it 'must output a "created_at" key with the Report#created_at timestamp' do
      expect(output_json[:created_at]).to be == report.created_at.to_s
    end

    context "when vulnerabilities were found" do
      context "when the report contains InsecureSources" do
        let(:uri) { URI('git://github.com/foo/bar.git') }
        let(:insecure_source) do
          Bundler::Audit::Results::InsecureSource.new(uri)
        end

        let(:report) do
          super().tap do |report|
            report << insecure_source
          end
        end

        it 'must output the InsecureSource as JSON in the "results" Array' do
          expect(output_json[:results]).to be_kind_of(Array)
          expect(output_json[:results][0]).to be_kind_of(Hash)
          expect(output_json[:results][0][:type]).to be == 'insecure_source'
          expect(output_json[:results][0][:source]).to be == uri.to_s
        end
      end

      context "when the report contains UnpatchedGems" do
        let(:gem) do
          Gem::Specification.new do |spec|
            spec.name = 'test'
            spec.version = '0.1.0'
          end
        end

        let(:advisory) do
          Bundler::Audit::Advisory.load(Fixtures.join('advisory','CVE-2020-1234.yml'))
        end
        let(:unpatched_gem) do
          Bundler::Audit::Results::UnpatchedGem.new(gem,advisory)
        end

        let(:report) do
          super().tap do |report|
            report << unpatched_gem
          end
        end

        it 'must output the UnpatchedGem as JSON in the "results" Array' do
          expect(output_json[:results]).to be_kind_of(Array)
          expect(output_json[:results][0]).to be_kind_of(Hash)
          expect(output_json[:results][0][:type]).to be == 'unpatched_gem'
          expect(output_json[:results][0][:gem]).to be_kind_of(Hash)
          expect(output_json[:results][0][:gem][:name]).to be == gem.name
          expect(output_json[:results][0][:gem][:version]).to be == gem.version.to_s
          expect(output_json[:results][0][:advisory]).to be_kind_of(Hash)
          expect(output_json[:results][0][:advisory][:path]).to be == advisory.path
          expect(output_json[:results][0][:advisory][:id]).to be == advisory.id
          expect(output_json[:results][0][:advisory][:url]).to be == advisory.url
          expect(output_json[:results][0][:advisory][:title]).to be == advisory.title
          expect(output_json[:results][0][:advisory][:date]).to be == advisory.date.to_s
          expect(output_json[:results][0][:advisory][:description]).to be == advisory.description
          expect(output_json[:results][0][:advisory][:cvss_v2]).to be == advisory.cvss_v2
          expect(output_json[:results][0][:advisory][:cve]).to be == advisory.cve
          expect(output_json[:results][0][:advisory][:osvdb]).to be == advisory.osvdb
          expect(output_json[:results][0][:advisory][:ghsa]).to be == advisory.ghsa
          expect(output_json[:results][0][:advisory][:criticality]).to be == advisory.criticality.to_s.downcase
          expect(output_json[:results][0][:advisory][:unaffected_versions]).to be == advisory.unaffected_versions.map(&:to_s)
          expect(output_json[:results][0][:advisory][:patched_versions]).to be == advisory.patched_versions.map(&:to_s)
        end
      end
    end

    context "when no vulnerabilities were found" do
      it 'must output an "results" key with an empty Array' do
        expect(output_json[:results]).to be_kind_of(Array)
        expect(output_json[:results]).to be_empty
      end
    end
  end
end
