# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module Prompt
  def prompt_to_continue(command, destination = 'local')
    puts "The following rsync command will be executed to update the #{destination} copy of the specs:"
    puts
    puts command
    puts
    puts "CAUTION: Any unsaved changes that exist within the #{destination} content will be OVERWRITTEN!"
    if destination.eql?('local')
      puts 'CAUTION 2: Before continuing, make sure your local repo is on the correct, synced branch!'
    end
    puts
    print "Do you wish to continue? ('y' to continue, return to cancel) [n] "
    continue = STDIN.gets.chomp
    if continue.casecmp('y') == 0
      system(command)
    else
      puts 'Cancelled'
    end
  end
end
