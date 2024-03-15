require 'yaml'
require 'erb'

module ActiveStorage
  class Migrator
    def self.migrate(from_service_name, to_service_name)
      yaml_with_env = ERB.new(File.read('config/storage.yml')).result
      configs = YAML.load(yaml_with_env)

      from_service = ActiveStorage::Service.configure(from_service_name, { from_service_name.to_sym => configs[from_service_name.to_s] })
      to_service = ActiveStorage::Service.configure(to_service_name, { to_service_name.to_sym => configs[to_service_name.to_s] })

      # Check if services are configured correctly
      if from_service.nil? || to_service.nil?
        puts "Error: The services '#{from_service_name}' or '#{to_service_name}' are not configured correctly."
        return
      end

      # Configure the blob service for the source service
      ActiveStorage::Blob.service = from_service

      puts "#{ActiveStorage::Blob.count} Blobs to migrate from #{from_service_name} to #{to_service_name}"
      ActiveStorage::Blob.find_each do |blob|
        next unless blob.image?

        print '.'

        blob.open do |io|
          checksum = blob.checksum
          to_service.upload(blob.key, io, checksum: checksum)
        end
      end
    end
  end
end
