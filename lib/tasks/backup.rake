namespace :db do
  require 'aws-sdk-s3'
  desc 'Backup database to AWS-S3'
  task backup: [:environment] do
    datestamp = Time.zone.now.strftime('%Y-%m-%d_%H-%M-%S')
    backup_filename = "data-base-#{datestamp}.sql"
    file_path = '/home/chatwoot/chatwoot/tmp/backup/'

    # process backup
    `pg_dump #{ENV['POSTGRES_DATABASE']}  > #{file_path}#{backup_filename}`
    `gzip -9 #{file_path}#{backup_filename}`
    puts "Created backup: #{file_path}#{backup_filename}"

    # save to aws-s3
    bucket_name = ENV['S3_BUCKET_NAME']
    s3 = Aws::S3::Client.new(access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                             secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
                             region: ENV['AWS_REGION'])

    # complete_file_path = "#{file_path}#{backup_filename
    complete_file_path = "#{file_path}#{backup_filename}.gz"
    response = s3.put_object(
      bucket: bucket_name,
      key: "database_backup/#{backup_filename}.gz",
      body: File.read(complete_file_path),
      acl: 'private'
    )

    `rm -f #{file_path}#{backup_filename}.gz`
  end
end
