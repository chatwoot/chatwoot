require 'rails_helper'
require Rails.root.join('scripts/security/bundler_audit')

RSpec.describe BundlerAuditExceptions do
  let(:root) { Pathname(Dir.mktmpdir) }
  let(:database) { Bundler::Audit::Database.new(root.join('advisory-db').to_s) }
  let(:audit) { described_class.new(root: root.to_s, database: database) }
  let(:gh_log) { root.join('gh.log') }
  let(:open_issues) { '[]' }

  before do
    root.join('Gemfile.lock').write(<<~LOCK)
      GEM
        remote: https://rubygems.org/
        specs:
          rack (2.2.3)
          rake (13.0.0)

      PLATFORMS
        ruby

      DEPENDENCIES
        rack
        rake
    LOCK
    advisory('rack', 'CVE-2099-0001', ghsa: 'aaaa-bbbb-cccc', patched: '>= 2.2.4')
    advisory('rack', 'CVE-2099-0002', ghsa: 'dddd-eeee-ffff', patched: '>= 2.2.5')
    advisory('rake', 'CVE-2099-0003', ghsa: 'gggg-hhhh-iiii', patched: '>= 13.0.1')
    fake_gh
  end

  after { FileUtils.remove_entry(root) }

  def advisory(gem, cve, ghsa:, patched:)
    dir = root.join('advisory-db/gems', gem)
    dir.mkpath
    dir.join("#{cve}.yml").write({
      'gem' => gem, 'cve' => cve.delete_prefix('CVE-'), 'ghsa' => ghsa, 'url' => "https://example.test/#{cve}",
      'title' => "#{gem} issue #{cve}", 'date' => '2099-01-01', 'patched_versions' => [patched]
    }.to_yaml)
  end

  def ignore(*ids)
    root.join('.bundler-audit.yml').write({ 'ignore' => ids }.to_yaml)
  end

  # Records every call; `issue list` answers with the open issues the example sets.
  def fake_gh
    bin = root.join('bin')
    bin.mkpath
    bin.join('gh').write(<<~SH)
      #!/bin/sh
      printf '%s\\n' "$*" >> '#{gh_log}'
      case "$1 $2" in "issue list") cat '#{root.join('open_issues.json')}' ;; esac
    SH
    bin.join('gh').chmod(0o755)
  end

  def sync_issue
    root.join('open_issues.json').write(open_issues)
    with_modified_env(PATH: "#{root.join('bin')}:#{ENV.fetch('PATH')}") { audit.sync_issue }
    gh_log.exist? ? gh_log.readlines(chomp: true) : []
  end

  describe '#stale_ignores' do
    it 'names the ignored ids that no longer match any vulnerable gem in Gemfile.lock' do
      ignore('CVE-2099-0001', 'GHSA-dddd-eeee-ffff', 'CVE-2099-9999')

      expect(audit.stale_ignores).to eq(['CVE-2099-9999'])
    end

    it 'treats an id as stale once the locked version is patched' do
      ignore('CVE-2099-0003')
      root.join('Gemfile.lock').write(root.join('Gemfile.lock').read.sub('rake (13.0.0)', 'rake (13.0.1)'))

      expect(audit.stale_ignores).to eq(['CVE-2099-0003'])
    end
  end

  describe '#untriaged' do
    it 'keeps an advisory out when any of its ids is ignored' do
      ignore('GHSA-aaaa-bbbb-cccc', 'CVE-2099-0002')

      expect(audit.untriaged.map { |_gem, advisory| advisory.cve_id }).to eq(['CVE-2099-0003'])
    end
  end

  describe '#sync_issue' do
    before { ignore('CVE-2099-0001', 'CVE-2099-0002') }

    it 'opens the tracking issue listing the untriaged advisory' do
      calls = sync_issue

      expect(calls.last).to start_with("issue create --title #{described_class::ISSUE_TITLE} --body-file ")
      expect(audit.issue_body).to include('rake 13.0.0', 'CVE-2099-0003', 'GHSA-gggg-hhhh-iiii', '>= 13.0.1')
    end

    context 'when the tracking issue is already open' do
      let(:open_issues) { [{ number: 7, title: "Re: #{described_class::ISSUE_TITLE}" }, { number: 42, title: described_class::ISSUE_TITLE }].to_json }

      it 'updates it instead of opening another' do
        expect(sync_issue.last).to start_with('issue edit 42 --body-file ')
      end

      it 'leaves it alone once nothing needs triage' do
        ignore('CVE-2099-0001', 'CVE-2099-0002', 'CVE-2099-0003')

        expect(sync_issue).to be_empty
      end
    end

    it 'does nothing when nothing needs triage and no issue is open' do
      ignore('CVE-2099-0001', 'CVE-2099-0002', 'CVE-2099-0003')

      expect(sync_issue).to be_empty
    end

    it 'reports stale ignores in the issue too' do
      ignore('CVE-2099-0001', 'CVE-2099-0002', 'CVE-2099-0003', 'CVE-2099-9999')

      expect(sync_issue.last).to start_with('issue create ')
      expect(audit.issue_body).to include('CVE-2099-9999')
    end
  end
end
