ActiveRecord::Schema.define version: 0 do
  create_table ActsAsTaggableOn.tags_table, force: true do |t|
    t.string :name
    t.integer :taggings_count, default: 0
    t.string :type
  end
  add_index ActsAsTaggableOn.tags_table, ['name'], name: 'index_tags_on_name', unique: true

  create_table ActsAsTaggableOn.taggings_table, force: true do |t|
    t.integer :tag_id

    # You should make sure that the column created is
    # long enough to store the required class names.
    t.string :taggable_type
    t.integer :taggable_id

    t.string :tagger_type
    t.integer :tagger_id

    # Limit is created to prevent MySQL error on index
    # length for MyISAM table type: http://bit.ly/vgW2Ql
    t.string :context, limit: 128

    t.string :tenant , limit: 128

    t.datetime :created_at
  end
  add_index ActsAsTaggableOn.taggings_table,
            ['tag_id', 'taggable_id', 'taggable_type', 'context', 'tagger_id', 'tagger_type'],
            unique: true, name: 'taggings_idx'
  add_index ActsAsTaggableOn.taggings_table, :tag_id , name: 'index_taggings_on_tag_id'

  # above copied from
  # generators/acts_as_taggable_on/migration/migration_generator

  create_table :taggable_models, force: true do |t|
    t.column :name, :string
    t.column :type, :string
    t.column :tenant_id, :integer
  end

  create_table :columns_override_models, force: true do |t|
    t.column :name, :string
    t.column :type, :string
    t.column :ignored_column, :string
  end

  create_table :non_standard_id_taggable_models, primary_key: 'an_id', force: true do |t|
    t.column :name, :string
    t.column :type, :string
  end

  create_table :untaggable_models, force: true do |t|
    t.column :taggable_model_id, :integer
    t.column :name, :string
  end

  create_table :cached_models, force: true do |t|
    t.column :name, :string
    t.column :type, :string
    t.column :cached_tag_list, :string
  end

  create_table :other_cached_models, force: true do |t|
    t.column :name, :string
    t.column :type, :string
    t.column :cached_language_list, :string
    t.column :cached_status_list, :string
    t.column :cached_glass_list, :string
  end

  create_table :companies, force: true do |t|
    t.column :name, :string
  end

  create_table :users, force: true do |t|
    t.column :name, :string
  end

  create_table :other_taggable_models, force: true do |t|
    t.column :name, :string
    t.column :type, :string
  end

  create_table :ordered_taggable_models, force: true do |t|
    t.column :name, :string
    t.column :type, :string
  end

  create_table :cache_methods_injected_models, force: true do |t|
    t.column :cached_tag_list, :string
  end

  # Special cases for postgresql
  if using_postgresql?

    create_table :other_cached_with_array_models, force: true do |t|
      t.column :name, :string
      t.column :type, :string
      t.column :cached_language_list, :string, array: true
      t.column :cached_status_list, :string, array: true
      t.column :cached_glass_list, :string, array: true
    end

    if postgresql_support_json?
      create_table :taggable_model_with_jsons, :force => true do |t|
        t.column :name, :string
        t.column :type, :string
        t.column :opts, :json
      end
    end
  end
end
