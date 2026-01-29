class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    # Cache setup happens automatically when the model loads
  end
end
