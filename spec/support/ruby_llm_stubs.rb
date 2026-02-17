RSpec.configure do |config|
  config.before do
    models_instance = RubyLLM.models
    allow(models_instance).to receive(:refresh!)
    allow(models_instance).to receive(:save_to_json)
  end
end
