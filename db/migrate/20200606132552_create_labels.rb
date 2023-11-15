class CreateLabels < ActiveRecord::Migration[6.0]
  def change
    create_table :labels do |t|
      t.string :title
      t.text :description
      t.string :color
      t.boolean :show_on_sidebar
      t.references :account, index: true

      t.timestamps
    end
  end
end
