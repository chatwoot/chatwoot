class Features::ResponseBotService < Features::BaseService
  def enable_in_installation
    enable_vector_extension
    create_tables
  end

  def disable_in_installation
    drop_tables
    disable_vector_extension
  end

  def enable_vector_extension
    MIGRATION_VERSION.enable_extension 'vector'
  rescue ActiveRecord::StatementInvalid
    print 'Vector extension not available'
  end

  def disable_vector_extension
    MIGRATION_VERSION.disable_extension 'vector'
  end

  def create_tables
    return unless vector_extension_enabled?

    %i[response_sources response_documents responses inbox_response_sources].each do |table|
      send("create_#{table}_table")
    end
  end

  def drop_tables
    %i[responses response_documents response_sources inbox_response_sources].each do |table|
      MIGRATION_VERSION.drop_table table if MIGRATION_VERSION.table_exists?(table)
    end
  end

  private

  def create_inbox_response_sources_table
    return if MIGRATION_VERSION.table_exists?(:inbox_response_sources)

    MIGRATION_VERSION.create_table :inbox_response_sources do |t|
      t.references :inbox, null: false
      t.references :response_source, null: false
      t.index [:inbox_id, :response_source_id], name: 'index_inbox_response_sources_on_inbox_id_and_response_source_id', unique: true
      t.index [:response_source_id, :inbox_id], name: 'index_inbox_response_sources_on_response_source_id_and_inbox_id', unique: true
      t.timestamps
    end
  end

  def create_response_sources_table
    return if MIGRATION_VERSION.table_exists?(:response_sources)

    MIGRATION_VERSION.create_table :response_sources do |t|
      t.integer :source_type, null: false, default: 0
      t.string :name, null: false
      t.string :source_link
      t.references :source_model, polymorphic: true
      t.bigint :account_id, null: false
      t.timestamps
    end
  end

  def create_response_documents_table
    return if MIGRATION_VERSION.table_exists?(:response_documents)

    MIGRATION_VERSION.create_table :response_documents do |t|
      t.bigint :response_source_id, null: false
      t.string :document_link
      t.references :document, polymorphic: true
      t.text :content
      t.bigint :account_id, null: false
      t.timestamps
    end

    MIGRATION_VERSION.add_index :response_documents, :response_source_id
  end

  def create_responses_table
    return if MIGRATION_VERSION.table_exists?(:responses)

    MIGRATION_VERSION.create_table :responses do |t|
      t.bigint :response_source_id, null: false
      t.bigint :response_document_id
      t.string :question, null: false
      t.text :answer, null: false
      t.integer :status, default: 0
      t.bigint :account_id, null: false
      t.vector :embedding, limit: 1536
      t.timestamps
    end

    MIGRATION_VERSION.add_index :responses, :response_document_id
    MIGRATION_VERSION.add_index :responses, :embedding, using: :ivfflat, opclass: :vector_l2_ops
  end
end
