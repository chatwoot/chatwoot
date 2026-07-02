class RenameProspectingSearchCacheKey < ActiveRecord::Migration[7.1]
  def change
    rename_column :autonomia_prospecting_searches, :cache_key, :cache_fingerprint
    rename_index :autonomia_prospecting_searches,
                 'idx_autonomia_prospecting_searches_acc_cache',
                 'idx_autonomia_prospecting_searches_acc_cache_fp'
  end
end
