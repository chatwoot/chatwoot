class AddRegexToCustomAttributeDefinition < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_attribute_definitions, :regex_pattern, :string
    add_column :custom_attribute_definitions, :regex_cue, :string
  end
end
