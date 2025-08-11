require "active_storage/service/s3_service"

module ActiveStorage
  class Service::S3WithPrefixService < Service::S3Service
    def initialize(prefix: nil, **options)
      super(**options)
      @key_prefix = prefix.to_s.delete_prefix("/")
      @key_prefix = nil if @key_prefix.empty?
    end

    private

    def object_for(key)
      namespaced_key = @key_prefix ? File.join(@key_prefix, key) : key
      bucket.object(namespaced_key)
    end
  end
end 