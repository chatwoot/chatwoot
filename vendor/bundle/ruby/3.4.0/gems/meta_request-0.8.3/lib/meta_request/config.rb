# frozen_string_literal: true

module MetaRequest
  class Config
    attr_writer :logger, :storage_pool_size, :source_path

    # logger used for reporting gem's fatal errors
    def logger
      @logger ||= Logger.new(File.join(Rails.root, 'log', 'meta_request.log'))
    end

    # Number of files kept in storage.
    # Increase when using an application loading many simultaneous requests.
    def storage_pool_size
      @storage_pool_size ||= 20
    end

    def source_path
      @source_path ||= ENV['SOURCE_PATH'] || Rails.root.to_s
    end

    # List of relative paths inside Rails app. Used in Location calculation.
    def ignored_paths
      self.ignored_paths = %w[bin vendor] unless @ignored_paths
      @ignored_paths
    end

    def ignored_paths=(paths)
      @ignored_paths = paths.map do |path|
        Rails.root.join(path).to_s.freeze
      end.freeze
    end
  end
end
