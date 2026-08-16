# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'active_storage/service/s3_service'

service = ActiveStorage::Blob.service
manifest = if service.is_a?(ActiveStorage::Service::S3Service)
             bucket = service.bucket.name
             api = service.client.client
             versioning = api.get_bucket_versioning(bucket: bucket).status
             raise 'Object storage bucket versioning must be Enabled' unless versioning == 'Enabled'

             versions = ActiveStorage::Blob.distinct.pluck(:key).map do |key|
               current = api.head_object(bucket: bucket, key: key)
               raise "Object storage did not return a version ID for #{key}" if current.version_id.to_s.empty?

               {
                 'key' => key,
                 'version_id' => current.version_id,
                 'etag' => current.etag,
                 'size' => current.content_length
               }
             end

             {
               'service' => 's3_compatible',
               'bucket' => bucket,
               'versioning' => versioning,
               'objects' => versions.sort_by { |entry| entry.fetch('key') }
             }
           else
             { 'service' => 'local', 'objects' => [] }
           end

output_path = '/bootstrap-output/object-storage-manifest.json'
temporary_path = "#{output_path}.tmp.#{Process.pid}"
File.write(temporary_path, JSON.generate(manifest), mode: 'w', perm: 0o600)
File.rename(temporary_path, output_path)
File.chmod(0o600, output_path)
