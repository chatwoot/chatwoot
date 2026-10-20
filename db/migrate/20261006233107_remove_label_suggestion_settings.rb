class RemoveLabelSuggestionSettings < ActiveRecord::Migration[7.1]
  def up
    # rubocop:disable Rails/SkipsModelValidations
    Account.where("settings -> 'captain_models' ? 'label_suggestion' OR settings -> 'captain_features' ? 'label_suggestion'")
           .update_all("settings = settings #- '{captain_models,label_suggestion}' #- '{captain_features,label_suggestion}'")
    Integrations::Hook.where(app_id: 'openai')
                      .where("settings ? 'label_suggestion'")
                      .update_all("settings = settings - 'label_suggestion'")
    # rubocop:enable Rails/SkipsModelValidations
  end
end
