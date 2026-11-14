require 'rails_helper'

RSpec.describe SecurityBackport do
  let(:ignored) { YAML.load_file(Rails.root.join('.bundler-audit.yml')).fetch('ignore') }

  it 'has the backports in config/initializers/monkey_patches registered' do
    expect(described_class.entries.map(&:advisory)).to include('GHSA-v924-7rp8-4mxh', 'GHSA-8474-xrp6-wh69')
  end

  # When this fails the installed gem already ships the fix: delete the backport, its spec and
  # its .bundler-audit.yml entry, instead of keeping a copy that overrides upstream's code.
  described_class.entries.each do |entry|
    it "still needs the #{entry.advisory} backport for #{entry.gem_name} outside #{entry.patched.join(' | ')}" do
      expect(entry).to be_needed,
                       "#{entry.gem_name} #{entry.installed_version} ships the fix for #{entry.advisory}: remove the backport and its ignore"
    end

    it "keeps #{entry.advisory} in .bundler-audit.yml while the backport covers it" do
      expect(ignored).to include(entry.advisory)
    end
  end

  describe SecurityBackport::Entry do
    let(:patched) { ['~> 8.0.5, >= 8.0.5.2', '>= 8.1.4.1'] }

    def needed_on(version)
      described_class.new(advisory: 'GHSA-test', gem_name: 'activesupport', patched: patched).needed?(Gem::Version.new(version))
    end

    it 'applies on every version no patched range covers, including a later release line before its own fix' do
      expect(%w[7.2.3.1 8.0.5.1 8.1.0 8.1.4].map { |version| needed_on(version) }).to all(be(true))
    end

    it 'stops applying once the version is inside one of the patched ranges' do
      expect(%w[8.0.5.2 8.0.6 8.1.4.1 9.0.0].map { |version| needed_on(version) }).to all(be(false))
    end
  end

  describe '.register' do
    it 'answers whether the backport applies to the installed version' do
      installed = Gem.loaded_specs.fetch('activesupport').version

      expect(described_class.register(advisory: 'GHSA-test-new', gem_name: 'activesupport', patched: [">= #{installed.bump}"])).to be(true)
      expect(described_class.register(advisory: 'GHSA-test-old', gem_name: 'activesupport', patched: [">= #{installed}"])).to be(false)
    ensure
      described_class.entries.reject! { |entry| entry.advisory.start_with?('GHSA-test-') }
    end
  end
end
