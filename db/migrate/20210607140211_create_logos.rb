class CreateLogos < ActiveRecord::Migration[6.0]
  def change
    create_table :logos do |t|
      t.string :title

      t.timestamps
    end
  end
end
