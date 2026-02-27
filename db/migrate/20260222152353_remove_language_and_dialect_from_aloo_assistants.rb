# frozen_string_literal: true

class RemoveLanguageAndDialectFromAlooAssistants < ActiveRecord::Migration[7.0]
  def change
    remove_column :aloo_assistants, :language, :string, default: 'en'
    remove_column :aloo_assistants, :dialect, :string
  end
end
