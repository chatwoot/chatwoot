# This migration comes from acts_as_taggable_on_engine (originally 6)
class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :taggings, :tag_id
    add_index :taggings, :taggable_id
    add_index :taggings, :taggable_type
    add_index :taggings, :tagger_id
    add_index :taggings, :context

    add_index :taggings, [:tagger_id, :tagger_type]
    add_index :taggings, [:taggable_id, :taggable_type, :tagger_id, :context], name: 'taggings_idy'
  end
end
