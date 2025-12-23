# frozen_string_literal: true

require "active_record/connection_adapters/trilogy_adapter"
require "activerecord-import/adapters/trilogy_adapter"

class ActiveRecord::ConnectionAdapters::TrilogyAdapter
  include ActiveRecord::Import::TrilogyAdapter
end
