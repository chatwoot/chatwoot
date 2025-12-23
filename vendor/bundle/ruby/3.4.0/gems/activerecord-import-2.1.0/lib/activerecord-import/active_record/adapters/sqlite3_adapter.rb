# frozen_string_literal: true

require "active_record/connection_adapters/sqlite3_adapter"
require "activerecord-import/adapters/sqlite3_adapter"

class ActiveRecord::ConnectionAdapters::SQLite3Adapter
  include ActiveRecord::Import::SQLite3Adapter
end
