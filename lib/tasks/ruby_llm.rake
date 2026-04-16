# Refresh the RubyLLM model registry from models.dev and configured providers.
# Updates config/llm_models.json so new models are available without a gem upgrade.
#
# Usage:
#   bundle exec rake ruby_llm:refresh_models
#
# Run this when new models are released, commit the updated config/llm_models.json.
namespace :ruby_llm do
  desc 'Refresh RubyLLM model registry from models.dev'
  task refresh_models: :environment do
    registry_path = Rails.root.join('config/llm_models.json').to_s
    puts 'Refreshing RubyLLM model registry...'
    RubyLLM.models.refresh!
    RubyLLM.models.save_to_json(registry_path)
    puts "RubyLLM model registry updated with #{RubyLLM.models.all.size} models at #{registry_path}"
  end
end
