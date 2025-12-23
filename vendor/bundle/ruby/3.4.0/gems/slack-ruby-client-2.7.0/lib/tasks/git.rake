# frozen_string_literal: true
namespace :slack do
  # update slack-api-ref from https://github.com/slack-ruby/slack-api-ref
  task :git_update do
    sh 'git submodule update --init --recursive'
    sh 'git submodule foreach git pull origin master'
  end
end
