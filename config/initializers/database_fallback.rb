require 'active_record'

replica_available = ActiveRecord::Base.connection_pool.with_connection do |conn|
  conn.execute('SELECT 1 FROM primary_replica LIMIT 1')
  true
rescue StandardError
  false
end

Rails.application.config.to_prepare do
  ApplicationRecord.connects_to database: {
    writing: :primary,
    reading: replica_available ? :primary_replica : :primary
  }
end
