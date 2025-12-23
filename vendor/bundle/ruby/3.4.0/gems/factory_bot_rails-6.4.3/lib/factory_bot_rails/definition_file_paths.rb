# frozen_string_literal: true

module FactoryBotRails
  class DefinitionFilePaths
    def initialize(definition_file_paths)
      @files = []
      @directories = {}

      definition_file_paths.each do |path|
        @files << "#{path}.rb"
        @directories[path.to_s] = [:rb]
      end
    end

    def directories
      @directories.select { |path| Dir.exist?(path) }
    end

    def files
      @files.select { |file| File.exist?(file) }
    end

    def any?
      directories.any? || files.any?
    end
  end
end
