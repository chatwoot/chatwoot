# frozen_string_literal: true

require "activerecord-import/adapters/mysql_adapter"

module ActiveRecord::Import::TrilogyAdapter
  include ActiveRecord::Import::MysqlAdapter
end
