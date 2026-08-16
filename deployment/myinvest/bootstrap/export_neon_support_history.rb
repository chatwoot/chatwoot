# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'pg'
require 'time'

source_database_url = ENV.fetch('SOURCE_DATABASE_URL')
output_dir = File.expand_path(ENV.fetch('EXPORT_OUTPUT_DIR', '/history-export'))
tenant_key = ENV.fetch('TENANT_KEY', 'new_academy')

raise 'Neon support history belongs to new_academy' unless tenant_key == 'new_academy'

FileUtils.mkdir_p(output_dir, mode: 0o700)
FileUtils.chmod(0o700, output_dir)

rows = PG.connect(source_database_url) do |connection|
  connection.exec(<<~SQL).to_a
    SELECT id::text, session_id::text, role::text, content::text,
           channel::text, created_at
    FROM support_chat_messages
    ORDER BY session_id, created_at, id
  SQL
end

raise 'No Neon support history found' if rows.empty?
raise 'Unexpected channel in Neon support history' unless rows.all? { |row| row.fetch('channel') == 'web' }
raise 'Unexpected role in Neon support history' unless rows.all? { |row| %w[user assistant].include?(row.fetch('role')) }
raise 'Empty message in Neon support history' if rows.any? { |row| row.fetch('content').strip.empty? }

def iso8601(value)
  Time.parse(value).utc.iso8601(6)
end

def write_ndjson(path, records)
  File.open(path, File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
    records.each { |record| file.puts(JSON.generate(record)) }
  end
  File.chmod(0o600, path)
end

grouped_rows = rows.group_by { |row| row.fetch('session_id') }
contacts = grouped_rows.map do |session_id, messages|
  {
    external_id: "neon-support-contact:#{session_id}",
    name: 'Academy Website Chat',
    created_at: iso8601(messages.first.fetch('created_at')),
    updated_at: iso8601(messages.last.fetch('created_at'))
  }
end
conversations = grouped_rows.map do |session_id, messages|
  {
    external_id: "neon-support-conversation:#{session_id}",
    contact_external_id: "neon-support-contact:#{session_id}",
    status: 'resolved',
    created_at: iso8601(messages.first.fetch('created_at')),
    updated_at: iso8601(messages.last.fetch('created_at'))
  }
end
messages = rows.map do |row|
  {
    external_id: "neon-support-message:#{row.fetch('id')}",
    conversation_external_id: "neon-support-conversation:#{row.fetch('session_id')}",
    direction: row.fetch('role') == 'user' ? 'incoming' : 'outgoing',
    content: row.fetch('content'),
    created_at: iso8601(row.fetch('created_at')),
    updated_at: iso8601(row.fetch('created_at')),
    attachments: [],
    metadata: { source: 'academy_website_support', channel: 'web' }
  }
end

files = {
  contacts: ['contacts.ndjson', contacts],
  conversations: ['conversations.ndjson', conversations],
  messages: ['messages.ndjson', messages]
}
file_manifest = files.to_h do |key, (filename, records)|
  path = File.join(output_dir, filename)
  write_ndjson(path, records)
  [key, { path: filename, sha256: Digest::SHA256.file(path).hexdigest, count: records.length }]
end
export_digest = Digest::SHA256.hexdigest(file_manifest.values.map { |entry| entry.fetch(:sha256) }.join(':'))
manifest = {
  schema_version: 1,
  source_namespace: 'neon_academy_website_support',
  export_id: "neon-academy-support-#{export_digest}",
  tenant_key: tenant_key,
  created_at: Time.now.utc.iso8601(6),
  knowledge_import: false,
  files: file_manifest
}
manifest_path = File.join(output_dir, 'manifest.json')
File.write(manifest_path, JSON.pretty_generate(manifest) + "\n", mode: 'w', perm: 0o600)
File.chmod(0o600, manifest_path)

puts JSON.generate(
  tenant_key: tenant_key,
  contacts: contacts.length,
  conversations: conversations.length,
  messages: messages.length,
  knowledge_import: false,
  export_id: manifest.fetch(:export_id)
)
