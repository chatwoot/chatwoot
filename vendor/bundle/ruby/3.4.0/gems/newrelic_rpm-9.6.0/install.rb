# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

if __FILE__ == $0 || $0.include?('script/plugin') || File.basename($0) == 'rake'
  $LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
  require 'new_relic/cli/command'
  begin
    NewRelic::Cli::Install.new(:quiet => true, :app_name => 'My Application').run
  rescue NewRelic::Cli::Command::CommandFailure => e
    $stderr.puts e.message
  end
end
