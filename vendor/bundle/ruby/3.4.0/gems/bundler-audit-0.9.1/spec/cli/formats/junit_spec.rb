require 'spec_helper'
require 'bundler/audit/cli/formats'
require 'bundler/audit/cli/formats/junit'
require 'bundler/audit/report'

describe Bundler::Audit::CLI::Formats::Junit do
  it "must register the 'junit' format" do
    expect(Bundler::Audit::CLI::Formats[:junit]).to be described_class
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

        it 'must print "Insecure Source URI found: ..."' do
          expect(output).to include("Insecure Source URI found: #{uri}")
        end

        it 'must print have a positive number of failures' do
          expect(output).to match(/failures="[1-9][0-9]*"/)
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

        it "must print 'Name: ...'" do
          expect(output).to include("Name: #{gem.name}")
        end

        it "must print 'Version: ...'" do
          expect(output).to include("Version: #{gem.version}")
        end

        context "when the advisory has a CVE ID" do
          it "must print 'CVE: CVE-YYYY-NNNN'" do
            expect(output).to include("Advisory: CVE-#{advisory.cve} GHSA-aaaa-bbbb-cccc")
          end
        end

        context "when the advisory does not have a CVE ID" do
          let(:advisory) do
            super().tap do |advisory|
              advisory.cve = nil
            end
          end

          it "must not print 'CVE: CVE-YYYY-NNNN'" do
            expect(output).to_not include("CVE-")
          end
        end

        context "when the advisory has a GHSA ID" do
          it "must print 'GHSA-xxxx-xxxx-xxxx'" do
            expect(output).to include("GHSA-#{advisory.ghsa}")
          end
        end

        context "when the advisory does not have a GHSA ID" do
          let(:advisory) do
            super().tap do |advisory|
              advisory.ghsa = nil
            end
          end

          it "must not print 'GHSA-xxxx-xxxx-xxxx'" do
            expect(output).to_not include("GHSA-#{advisory.ghsa}")
          end
        end

        context "when CVSS v3 is present" do
          context "when Advisory#criticality is :none (cvss_v3 only)" do
            let(:advisory) do
              super().tap do |advisory|
                advisory.cvss_v3 = 0.0
              end
            end

            it "must print 'Criticality: None'" do
              expect(output).to include("Criticality: None")
            end
          end

          context "when Advisory#criticality is :low" do
            let(:advisory) do
              super().tap do |advisory|
                advisory.cvss_v3 = 0.1
              end
            end

            it "must print 'Criticality: Low'" do
              expect(output).to include("Criticality: Low")
            end
          end

          context "when Advisory#criticality is :medium" do
            let(:advisory) do
              super().tap do |advisory|
                advisory.cvss_v3 = 4.0
              end
            end

            it "must print 'Criticality: Medium'" do
              expect(output).to include("Criticality: Medium")
            end
          end

          context "when Advisory#criticality is :high" do
            let(:advisory) do
              super().tap do |advisory|
                advisory.cvss_v3 = 7.0
              end
            end

            it "must print 'Criticality: High'" do
              expect(output).to include("Criticality: High")
            end
          end

          context "when Advisory#criticality is :critical (cvss_v3 only)" do
            let(:advisory) do
              super().tap do |advisory|
                advisory.cvss_v3 = 9.0
              end
            end

            it "must print 'Criticality: High'" do
              expect(output).to include("Criticality: Critical")
            end
          end
        end

        context "when CVSS v2 is present" do
          let(:advisory) do
            super().tap do |advisory|
              advisory.cvss_v3 = nil
            end
          end

          context "when Advisory#criticality is :low" do
            let(:advisory) do
              super().tap do |advisory|
                advisory.cvss_v2 = 0.0
              end
            end

            it "must print 'Criticality: Low'" do
              expect(output).to include("Criticality: Low")
            end
          end

          context "when Advisory#criticality is :medium" do
            let(:advisory) do
              super().tap do |advisory|
                advisory.cvss_v2 = 4.0
              end
            end

            it "must print 'Criticality: Medium'" do
              expect(output).to include("Criticality: Medium")
            end
          end

          context "when Advisory#criticality is :high" do
            let(:advisory) do
              super().tap do |advisory|
                advisory.cvss_v2 = 7.0
              end
            end

            it "must print 'Criticality: High'" do
              expect(output).to include("Criticality: High")
            end
          end
        end

        it "must print 'URL: ...'" do
          expect(output).to include("URL: #{advisory.url}")
        end

        context "when :verbose is not enabled" do
          it 'must print "Title:" and the advisory description' do
            expect(output).to include("Title: #{advisory.title}")
          end
        end

        context "when Advisory#title contains XML special chars" do
          let(:advisory) do
            super().tap do |advisory|
              advisory.title = '<entity id="one">One</entity>'
            end
          end

          it 'must print "Title:" with escaped characters' do
            expect(output).to include("Title: #{CGI.escapeHTML(advisory.title)}")
          end
        end

        context "when Advisory#patched_versions is not empty" do
          it 'must print "Solution: upgrade to ..."' do
            expect(output).to include("Solution: upgrade to #{CGI.escapeHTML(advisory.patched_versions.map { |v| "'#{v}'" }.join(', '))}")
          end
        end

        context "when Advisory#patched_versions is empty" do
          let(:advisory) do
            super().tap do |advisory|
              advisory.patched_versions = []
            end
          end

          it 'must print "Solution: remove or disable this gem until a patch is available!"' do
            expect(output).to include("Solution: remove or disable this gem until a patch is available!")
          end
        end

        it 'must print have a positive number of failures' do
          expect(output).to match(/failures="[1-9][0-9]*"/)
        end
      end
    end

    context "when no vulnerabilities were found" do
      it 'must print an empty testsuite' do
        expect(output).to include('failures="0"')
      end

      context "when :quiet is enabled" do
        let(:options) { {quiet: true} }

        it "should print nothing" do
          expect(output).to be_empty
        end
      end
    end

    it "must restore $stdout" do
      expect($stdout).to_not be(stdout)
    end
  end
end
