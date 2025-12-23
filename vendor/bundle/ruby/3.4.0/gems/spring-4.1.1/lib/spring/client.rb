require "spring/errors"
require "spring/json"

require "spring/client/command"
require "spring/client/run"
require "spring/client/help"
require "spring/client/binstub"
require "spring/client/stop"
require "spring/client/status"
require "spring/client/rails"
require "spring/client/version"
require "spring/client/server"

module Spring
  module Client
    COMMANDS = {
      "help"      => Client::Help,
      "-h"        => Client::Help,
      "--help"    => Client::Help,
      "binstub"   => Client::Binstub,
      "stop"      => Client::Stop,
      "status"    => Client::Status,
      "rails"     => Client::Rails,
      "-v"        => Client::Version,
      "--version" => Client::Version,
      "server"    => Client::Server,
    }

    def self.run(args)
      command_for(args.first).call(args)
    rescue CommandNotFound
      Client::Help.call(args)
    rescue ClientError => e
      $stderr.puts e.message
      exit 1
    end

    def self.command_for(name)
      COMMANDS[name] || Client::Run
    end
  end
end

# allow users to add hooks that do not run in the server
# or modify start/stop
if File.exist?("config/spring_client.rb")
  require "./config/spring_client.rb"
end
