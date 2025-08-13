Searchkick.queue_name = :async_database_migration if ENV.fetch('OPENSEARCH_URL', '').present?
