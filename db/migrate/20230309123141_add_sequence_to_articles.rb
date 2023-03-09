class AddSequenceToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :sequence, :integer
  end
end
