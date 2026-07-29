require 'yaml'
require 'erb'

class ActiveStorage::Migrator
  def self.migrate(from_service_name, to_service_name, should_update_service_name: true)
    configs = load_storage_config
    # Check if services are configured correctly
    if configs[from_service_name.to_s].nil? || configs[to_service_name.to_s].nil?
      raise "Error: The services '#{from_service_name}' or '#{to_service_name}' are not configured correctly."
    end

    from_service = configure_service(from_service_name, configs)

    configure_blob_service(from_service)

    migrate_blobs(from_service_name, to_service_name, should_update_service_name: should_update_service_name)
  end

  def self.load_storage_config
    yaml_with_env = ERB.new(File.read('config/storage.yml')).result
    YAML.load(yaml_with_env)
  end

  def self.configure_blob_service(service)
    ActiveStorage::Blob.service = service
  end

  def self.configure_service(service_name, configs = load_storage_config)
    service_config = configs[service_name.to_s]
    ActiveStorage::Service.configure(service_name, { service_name.to_sym => service_config })
  end

  def self.migrate_blobs(from_service_name, to_service_name, should_update_service_name: true)
    to_service = configure_service(to_service_name)
    blobs = ActiveStorage::Blob.where(service_name: from_service_name.to_s)
    Rails.logger.debug { "#{blobs.count} Blobs to migrate from #{from_service_name} to #{to_service_name}" }

    blobs.find_each do |blob|
      Rails.logger.debug { '.' }

      blob.open do |io|
        checksum = blob.checksum
        to_service.upload(blob.key, io, checksum: checksum)
      end

      blob.update!(service_name: to_service_name.to_s) if should_update_service_name
    rescue ActiveStorage::FileNotFoundError => e
      Rails.logger.warn { "Skipping missing blob #{blob.id} (#{blob.key}): #{e.message}" }
    end
    Rails.logger.debug { 'Successful migration' }
  end
end
