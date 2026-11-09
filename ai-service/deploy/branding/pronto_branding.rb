# Pronto branding for Chatwoot (InstallationConfig only; no Chatwoot files touched).
# Usage inside the rails container:
#   bundle exec rails runner /tmp/pronto/pronto_branding.rb backup /tmp/pronto/backup.json
#   bundle exec rails runner /tmp/pronto/pronto_branding.rb apply  /tmp/pronto/values.json
#   bundle exec rails runner /tmp/pronto/pronto_branding.rb apply  /tmp/pronto/backup.json   # rollback
require 'json'

KEYS = %w[
  INSTALLATION_NAME BRAND_NAME LOGO LOGO_DARK LOGO_THUMBNAIL
  BRAND_URL WIDGET_BRAND_URL DASHBOARD_SCRIPTS DISPLAY_MANIFEST
].freeze

mode, path = ARGV
abort 'usage: backup|apply <file>' unless %w[backup apply].include?(mode) && path

case mode
when 'backup'
  values = KEYS.to_h do |name|
    config = InstallationConfig.find_by(name: name)
    [name, config ? { 'present' => true, 'value' => config.value } : { 'present' => false }]
  end
  File.write(path, JSON.pretty_generate(values))
  values.each { |name, v| puts "#{name}: #{v['present'] ? "#{v['value'].to_s[0, 40].inspect} (#{v['value'].to_s.size} chars)" : 'not set'}" }
when 'apply'
  values = JSON.parse(File.read(path))
  values.each do |name, entry|
    raise "unexpected key #{name}" unless KEYS.include?(name)

    config = InstallationConfig.find_or_initialize_by(name: name)
    if entry['present'] == false
      config.destroy! if config.persisted?
      puts "#{name}: removed"
      next
    end
    config.value = entry['value']
    config.save!
    puts "#{name}: set (#{entry['value'].to_s.size} chars)"
  end
  GlobalConfig.clear_cache if GlobalConfig.respond_to?(:clear_cache)
end
