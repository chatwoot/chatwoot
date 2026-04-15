# Refresh the RubyLLM model registry from models.dev and configured providers.
# Updates the gem's bundled models.json so new models are available without a gem upgrade.
#
# Usage:
#   bundle exec rake ruby_llm:refresh_models
#
# Called during Docker image build and can be run manually in dev.
namespace :ruby_llm do
  desc 'Refresh RubyLLM model registry from models.dev'
  task refresh_models: :environment do
    puts 'Refreshing RubyLLM model registry...'
    RubyLLM.models.refresh!
    RubyLLM.models.save_to_json
    puts "RubyLLM model registry updated with #{RubyLLM.models.all.size} models"
  end
end
