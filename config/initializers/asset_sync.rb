if defined?(AssetSync)
  AssetSync.configure do |config|
    config.fog_provider = 'AWS'
    config.fog_directory = ENV.fetch('DO_SPACE_BUCKET', 'courier-bucket')
    config.aws_access_key_id = ENV.fetch('STORAGE_ACCESS_KEY_ID', nil)
    config.aws_secret_access_key = ENV.fetch('STORAGE_SECRET_ACCESS_KEY', nil)
    config.fog_region = ENV.fetch('DO_SPACE_REGION', 'nyc3')
    config.fog_host = "#{ENV.fetch('DO_SPACE_BUCKET', 'courier-bucket')}.#{ENV.fetch('DO_SPACE_REGION', 'nyc3')}.digitaloceanspaces.com"
    config.fog_public = true
    config.existing_remote_files = 'keep'
    config.gzip_compression = true
    config.manifest = true
    config.enabled = true
    config.add_local_file_paths do
      public_root = Rails.public_path
      Dir.chdir(public_root) do
        # Include Sprockets (assets), Vite outputs and SDK packs
        assets_files = Dir['assets/**/*']
        vite_files   = Dir['vite/**/*']
        packs_files  = Dir['packs/**/*']
        (assets_files + vite_files + packs_files).select { |f| File.file?(f) }
      end
    end
  end
end
