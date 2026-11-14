# frozen_string_literal: true

# Keeps .bundler-audit.yml honest. Run after `bundle exec bundle-audit update`:
#
#   ruby scripts/security/bundler_audit.rb stale   # exit 1 when an ignored id no longer matches
#                                                  # any vulnerable gem in Gemfile.lock
#   ruby scripts/security/bundler_audit.rb report  # open or update the tracking issue for
#                                                  # advisories nobody has triaged yet (needs gh)
#
# `stale` runs in the security-scan job of run_foss_spec.yml, `report` in the daily
# security_audit.yml workflow. The decision rule for each advisory is at the top of
# .bundler-audit.yml.
require 'bundler/audit/database'
require 'bundler/audit/scanner'
require 'json'
require 'open3'
require 'tempfile'
require 'yaml'

class BundlerAuditExceptions
  CONFIG = '.bundler-audit.yml'
  ISSUE_TITLE = 'security-scan: gem advisories need triage'

  def initialize(root: Dir.pwd, database: Bundler::Audit::Database.new)
    @root = root
    @database = database
  end

  def ignored
    YAML.load_file(File.join(@root, CONFIG)).fetch('ignore')
  end

  # Ignored ids that match no advisory for the locked gems: the fix landed, or the gem left.
  def stale_ignores
    ignored - advisories.flat_map { |_gem, advisory| advisory.identifiers }
  end

  # Matching advisories none of whose ids is ignored yet.
  def untriaged
    advisories.reject { |_gem, advisory| advisory.identifiers.intersect?(ignored) }
  end

  def sync_issue
    # Nothing to decide: leave any open issue as it is, a person closes it with the fix.
    return if untriaged.empty? && stale_ignores.empty?

    issue = open_issue

    Tempfile.create('bundler-audit-issue') do |file|
      file.write(issue_body)
      file.flush
      if issue
        gh('issue', 'edit', issue.to_s, '--body-file', file.path)
      else
        gh('issue', 'create', '--title', ISSUE_TITLE, '--body-file', file.path)
      end
    end
  end

  def issue_body
    lines = ['The daily audit found entries that need a decision under the rule at the top of `.bundler-audit.yml`.', '']
    if untriaged.any?
      lines << '## Advisories not triaged'
      untriaged.each { |gem, advisory| lines << advisory_line(gem, advisory) }
      lines << ''
    end
    if stale_ignores.any?
      lines << '## Stale ignores (remove from `.bundler-audit.yml`)'
      stale_ignores.each { |id| lines << "- #{id}" }
    end
    lines.join("\n")
  end

  private

  def advisory_line(gem, advisory)
    patched = advisory.patched_versions.empty? ? 'none' : advisory.patched_versions.map(&:to_s).join(', ')
    "- #{gem.name} #{gem.version}: #{advisory.identifiers.join(' / ')} #{advisory.title} (patched: #{patched}) #{advisory.url}"
  end

  # Every advisory for a locked gem, ignores included: the scanner reads no config file here.
  def advisories
    @advisories ||= Bundler::Audit::Scanner.new(@root, 'Gemfile.lock', @database, File.join(@root, '.no-bundler-audit-config'))
                                           .scan
                                           .grep(Bundler::Audit::Results::UnpatchedGem)
                                           .map { |result| [result.gem, result.advisory] }
  end

  def open_issue
    list = gh('issue', 'list', '--state', 'open', '--search', %(in:title "#{ISSUE_TITLE}"), '--json', 'number,title')
    JSON.parse(list).find { |issue| issue['title'] == ISSUE_TITLE }&.fetch('number')
  end

  def gh(*args)
    output, status = Open3.capture2e('gh', *args)
    raise "gh #{args.first(2).join(' ')} failed: #{output}" unless status.success?

    output
  end
end

if $PROGRAM_NAME == __FILE__
  audit = BundlerAuditExceptions.new
  case ARGV.first
  when 'stale'
    stale = audit.stale_ignores
    abort("Stale ignores in #{BundlerAuditExceptions::CONFIG}, remove them: #{stale.join(' ')}") if stale.any?
    puts "No stale ignores in #{BundlerAuditExceptions::CONFIG}."
  when 'report'
    audit.sync_issue
  else
    abort('usage: ruby scripts/security/bundler_audit.rb stale|report')
  end
end
