class AddFeatureCitationToAssistantConfig < ActiveRecord::Migration[7.1]
  def up
    Captain::Assistant.find_each do |assistant|
      assistant.update!(
        config: assistant.config.merge('feature_citation' => true)
      )
    end
  end

  def down
    Captain::Assistant.find_each do |assistant|
      config = assistant.config.dup
      config.delete('feature_citation')
      assistant.update!(config: config)
    end
  end
end
