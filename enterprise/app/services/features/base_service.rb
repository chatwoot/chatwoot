class Features::BaseService
  MIGRATION_VERSION = ActiveRecord::Migration[7.0]

  def vector_extension_enabled?
    ActiveRecord::Base.connection.extension_enabled?('vector')
  end
end
