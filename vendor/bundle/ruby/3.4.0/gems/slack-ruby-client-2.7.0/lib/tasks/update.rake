# frozen_string_literal: true
namespace :slack do
  namespace :api do
    desc 'Auto-generate automatic portions of the Slack API client.'
    task :update do
      Rake::Task['slack:real_time:api:update'].invoke
      Rake::Task['slack:web:api:update'].invoke
    end
  end
end
