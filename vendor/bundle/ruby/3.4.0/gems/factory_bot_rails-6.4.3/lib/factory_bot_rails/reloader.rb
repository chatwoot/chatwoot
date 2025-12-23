# frozen_string_literal: true

require "factory_bot_rails/definition_file_paths"

module FactoryBotRails
  class Reloader
    def initialize(app)
      @app = app
      @paths = DefinitionFilePaths.new(FactoryBot.definition_file_paths)
    end

    def run
      return unless @paths.any?

      register_reloader(build_reloader)
    end

    private

    attr_reader :app

    def build_reloader
      reloader_class.new(@paths.files, @paths.directories) do
        FactoryBot.reload
      end
    end

    def reloader_class
      app.config.file_watcher
    end

    def register_reloader(reloader)
      app.reloader.to_prepare do
        reloader.execute
      end

      app.reloaders << reloader
    end
  end
end
