# encoding: UTF-8

PryRails::Commands = Pry::CommandSet.new

command_glob = File.expand_path('../commands/*.rb', __FILE__)

Dir[command_glob].each do |command|
  require command
end

Pry.commands.import PryRails::Commands
