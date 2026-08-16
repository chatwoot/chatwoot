# frozen_string_literal: true

require 'cgi'
require 'json'
require 'active_storage/service/s3_service'

manifest = JSON.parse(File.read('/restore/object-storage-manifest.json'))
exit if manifest.fetch('service') == 'local'

service = ActiveStorage::Blob.service
raise 'Restore requires the S3-compatible Active Storage service' unless service.is_a?(ActiveStorage::Service::S3Service)

bucket = service.bucket.name
raise 'Restore bucket does not match the snapshot manifest' unless bucket == manifest.fetch('bucket')

api = service.client.client
raise 'Restore bucket versioning is not enabled' unless api.get_bucket_versioning(bucket: bucket).status == 'Enabled'

manifest.fetch('objects').each do |entry|
  key = entry.fetch('key')
  version_id = entry.fetch('version_id')
  expected_etag = entry.fetch('etag')
  expected_size = entry.fetch('size')
  version = api.head_object(bucket: bucket, key: key, version_id: version_id)
  unless version.etag == expected_etag && version.content_length == expected_size
    raise "Snapshot object integrity mismatch: #{key}"
  end

  current = begin
    api.head_object(bucket: bucket, key: key)
  rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
    nil
  end
  next if current&.etag == expected_etag && current&.content_length == expected_size

  encoded_key = key.split('/').map { |part| CGI.escape(part).gsub('+', '%20') }.join('/')
  encoded_version = CGI.escape(version_id).gsub('+', '%20')
  api.copy_object(
    bucket: bucket,
    key: key,
    copy_source: "#{bucket}/#{encoded_key}?versionId=#{encoded_version}"
  )
  restored = api.head_object(bucket: bucket, key: key)
  unless restored.etag == expected_etag && restored.content_length == expected_size
    raise "Restored object integrity mismatch: #{key}"
  end
end
