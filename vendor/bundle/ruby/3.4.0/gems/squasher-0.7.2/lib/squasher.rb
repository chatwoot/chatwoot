module Squasher
  extend self

  autoload :Cleaner, 'squasher/cleaner'
  autoload :Config,  'squasher/config'
  autoload :Render,  'squasher/render'
  autoload :VERSION, 'squasher/version'
  autoload :Worker,  'squasher/worker'

  attr_reader :config

  @config = Config.new

  def setup(options)
    options.each { |(k, v)| config.set(k, v) }
  end

  def squash(raw_date)
    parts = raw_date.to_s.split('/').map(&:to_i)
    date = Time.new(*parts)
    Worker.process(date)
  end

  def clean
    Cleaner.process
  end

  def rake(command, description = nil)
    tell(description) if description
    config.in_app_root do
      env = { 'RAILS_ENV' => 'development', 'DISABLE_DATABASE_ENVIRONMENT_CHECK' => '1' }
      system(env, "bundle exec rake #{ command }")
    end
  end

  def ask(*args)
    tell(*args)
    $stdin.gets[0].downcase == 'y'
  end

  def tell(key, options = {})
    message = messages.fetch(key.to_s)
    message = message.join("\n") if message.is_a?(Array)
    message = colorize(message)
    print(message, options)
  end

  def print(message, options = {})
    puts options.empty? ? message : message % options
  end

  def error(*args)
    tell(*args)
    abort
  end

  private

  def messages
    return @messages if @messages

    require 'yaml'
    path = File.join(File.dirname(__FILE__), 'squasher/messages.yml')
    @messages = YAML.load(File.open(path))
  end

  COLORS = ['red', 'green', 'yellow', 'blue'].each_with_index.inject({}) { |r, (k, i)| r.merge!(k => "03#{ i + 1 }") }

  def colorize(message)
    message.gsub(/\:(\w+)\<([^>]+)\>/) { |_| "\033[#{ COLORS[$1] }m#{ $2 }\033[039m" }
  end
end
