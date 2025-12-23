# frozen_string_literal: true

require "active_record/connection_adapters/mysql2_adapter"
require "activerecord-import/adapters/mysql2_adapter"

class ActiveRecord::ConnectionAdapters::Mysql2Adapter
  include ActiveRecord::Import::Mysql2Adapter
end
