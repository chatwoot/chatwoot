# config/initializers/asset_sync.rb
if Rails.env.development? || Rails.env.test?
  # Explicitly disable AssetSync in development/test
  if defined?(AssetSync)
    AssetSync.configure do |config|
      config.enabled = false
    end
  end
elsif defined?(AssetSync)
  AssetSync.configure do |config|
    config.fog_provider = 'AWS'
    config.fog_directory = ENV.fetch('CDN_BUCKET', 'courier-bucket')
    config.aws_access_key_id = ENV.fetch('CDN_ACCESS_KEY', nil)
    config.aws_secret_access_key = ENV.fetch('CDN_ACCESS_SECRET', nil)
    config.fog_region = ENV.fetch('CDN_REGION', 'nyc3')
    config.fog_host = "#{ENV.fetch('CDN_BUCKET')}.#{ENV.fetch('CDN_REGION')}.digitaloceanspaces.com"
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
