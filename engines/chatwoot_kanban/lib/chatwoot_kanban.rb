require 'chatwoot_kanban/version'
require 'chatwoot_kanban/engine'

module ChatwootKanban
  # Configuration container. Tweak from a Chatwoot initializer if needed:
  #
  #   ChatwootKanban.configure do |c|
  #     c.feature_flag = :kanban_boards
  #   end
  class Configuration
    attr_accessor :feature_flag, :default_column_names

    def initialize
      @feature_flag         = nil # nil = always enabled
      @default_column_names = %w[Backlog Doing Done]
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
