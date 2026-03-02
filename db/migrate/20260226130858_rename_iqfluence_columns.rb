class RenameIqfluenceColumns < ActiveRecord::Migration[7.1]
  def change
    rename_column :influencer_profiles, :iqfluence_report_id, :external_report_id
    rename_column :influencer_profiles, :iqfluence_search_result_id, :external_search_id
  end
end
