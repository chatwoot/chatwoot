# frozen_string_literal: true

require 'json'
require 'stringio'

unless ENV['RAILS_UPGRADE_ALLOW_STORAGE_WRITE'] == 'true'
  warn({ status: 'REFUSED', reason: 'Set RAILS_UPGRADE_ALLOW_STORAGE_WRITE=true to create and purge one test blob.' }.to_json)
  exit 1
end

service_name = ENV.fetch('RAILS_UPGRADE_STORAGE_SERVICE')
payload = "chatwoot-rails-upgrade-storage-smoke-#{SecureRandom.hex(16)}"
blob = nil

begin
  blob = ActiveStorage::Blob.create_and_upload!(
    io: StringIO.new(payload),
    filename: "rails-upgrade-smoke-#{SecureRandom.hex(8)}.txt",
    content_type: 'text/plain',
    service_name: service_name
  )

  raise 'Uploaded blob does not exist in the configured service' unless blob.service.exist?(blob.key)
  raise 'Downloaded blob did not match the uploaded payload' unless blob.download == payload

  puts({ status: 'PASS', service_name: service_name, service_class: blob.service.class.name }.to_json)
ensure
  blob&.purge
end
