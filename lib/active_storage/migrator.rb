require 'yaml'
require 'erb'
require 'logger'

class ActiveStorage::Migrator
  Rails.logger = Logger.new($stdout)
  Rails.logger.level = Logger::DEBUG

  def self.migrate(from_service_name, to_service_name)
    configs = load_storage_config
    # Check if services are configured correctly
    if configs[from_service_name.to_s].nil? || configs[to_service_name.to_s].nil?
      raise "Error: The services '#{from_service_name}' or '#{to_service_name}' are not configured correctly."
    end

    from_service = ActiveStorage::Service.configure(from_service_name, { from_service_name.to_sym => configs[from_service_name.to_s] })
    to_service = ActiveStorage::Service.configure(to_service_name, { to_service_name.to_sym => configs[to_service_name.to_s] })

    configure_blob_service(from_service)

    Rails.logger.debug { "#{ActiveStorage::Blob.count} Blobs to migrate from #{from_service_name} to #{to_service_name}" }

    migrate_blobs(from_service, to_service)
  end

  def self.load_storage_config
    yaml_with_env = ERB.new(File.read('config/storage.yml')).result
    YAML.load(yaml_with_env)
  end

  def self.configure_services(from_service_name, to_service_name, configs)
    from_service = ActiveStorage::Service.configure(from_service_name, { from_service_name.to_sym => configs[from_service_name.to_s] })
    to_service = ActiveStorage::Service.configure(to_service_name, { to_service_name.to_sym => configs[to_service_name.to_s] })
    [from_service, to_service]
  end

  def self.configure_service(service_name, configs)
    service_config = configs[service_name.to_s]
    ActiveStorage::Service.configure(service_name, { service_name.to_sym => service_config })
  end

  def self.configure_blob_service(service)
    ActiveStorage::Blob.service = service
  end

  def self.migrate_blobs(_from_service, to_service)
    # Configure the blob service for the source service
    ActiveStorage::Blob.find_each do |blob|
      next unless blob.image?

      Rails.logger.debug { '.' }

      blob.open do |io|
        checksum = blob.checksum
        to_service.upload(blob.key, io, checksum: checksum)
      end
    end
    Rails.logger.debug { 'Successful migration' }
  end
end
